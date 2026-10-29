module Oxidized
  module ManualBackupQueue
    # Manual requests use the normal worker without increasing its concurrency budget.
    def queue_backups(names = nil, options = {})
      with_lock do
        wanted = names.nil? ? map(&:name) : names.map(&:to_s).uniq
        selected = wanted.map { |name| self[find_node_index(name)] }
        @manual_backups ||= {}
        selected.each do |node|
          current = manual_backup_status(node)
          if node.running? || node.nexted? || %w[queued running].include?(current[:state])
            active = %w[queued running].include?(current[:state]) && @manual_backups[node.name]
            @manual_backups[node.name] = { requested_at: Time.now.utc, node: node } unless active
            next
          end

          @manual_backups[node.name] = { requested_at: Time.now.utc, node: node }
          node.user, node.email, node.msg, node.from = options.values_at('user', 'email', 'msg', 'from')
          node.last = nil
          node.nexted = true
          delete(node)
          put(node)
        end
        selected.map { |node| manual_backup_status(node) }
      end
    end

    # Called only after Worker has handled storage or exhausted collection retries.
    def finish_manual_backup(node)
      with_lock do
        record = (@manual_backups || {})[node.name]
        return unless any? { |current| current.equal?(node) }
        return unless record && record[:node].equal?(node) && !record[:result] && node.last && !node.nexted?

        record[:result] = { name: node.name, state: node.last.status == :success ? 'succeeded' : 'failed',
                            last_attempt_at: node.last.end, result: node.last.status,
                            requested_at: record[:requested_at] }
      end
    end

    def backup_status
      with_lock { map { |node| manual_backup_status(node) } }
    end

    private

    def manual_backup_status(node)
      record = (@manual_backups || {})[node.name]
      return record[:result].dup if record && record[:result]

      state = if record && !record[:node].equal?(node)
                'unknown'
              elsif node.running?
                'running'
              elsif node.nexted? || record
                'queued'
              else
                'not_requested'
              end
      { name: node.name, state: state, last_attempt_at: node.last&.end,
        result: node.last&.status, requested_at: record && record[:requested_at] }
    end
  end
end
