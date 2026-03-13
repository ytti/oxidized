module Oxidized
  require 'ipaddr'
  require 'oxidized/node'
  class NotSupported < OxidizedError; end
  class NodeNotFound < OxidizedError; end

  class Nodes < Array
    include SemanticLogger::Loggable

    attr_accessor :source, :jobs
    alias put unshift
    def load(node_want = nil)
      @source = Oxidized.config.source.default
      Oxidized.mgr.add_source(@source) || raise(MethodNotFound, "cannot load node source '#{@source}', not found")
      logger.info "Loading nodes"

      # All slow I/O (network fetch, DNS resolution, Node construction) runs outside
      # the mutex so that web-API calls remain responsive during a reload.
      raw_nodes  = Oxidized.mgr.source[@source].new.load node_want
      candidates = raw_nodes.select { |node| node_want?(node_want, node) }
      new_nodes  = build_nodes_parallel(candidates)

      # Only the atomic list swap needs the lock, keeping the critical section minimal.
      with_lock do
        size.zero? ? replace(new_nodes) : update_nodes(new_nodes)
        Output.clean_obsolete_nodes(self) if node_want.nil?
      end
      logger.info "Loaded #{size} nodes"
    end

    def node_want?(node_want, node)
      return true unless node_want

      # rubocop:disable Style/RedundantParentheses
      node_want_ip = (IPAddr.new(node_want) rescue false)
      name_is_ip   = (IPAddr.new(node[:name]) rescue false)
      # rubocop:enable Style/RedundantParentheses
      # rubocop:todo Lint/DuplicateBranch
      if name_is_ip && (node_want_ip == node[:name])
        true
      elsif node[:ip] && (node_want_ip == node[:ip])
        true
      elsif node_want.match node[:name]
        true unless name_is_ip
      end
      # rubocop:enable Lint/DuplicateBranch
    end

    def list
      with_lock do
        map { |e| e.serialize }
      end
    end

    def show(node)
      with_lock do
        i = find_node_index node
        self[i].serialize
      end
    end

    # Returns the configuration of group/node_name
    #
    # #fetch is called by oxidzed-web
    def fetch(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.fetch node, group
      end
    end

    # @param node [String] name of the node moved into the head of array
    def next(node, opt = {})
      return if running.find_index(node)

      logger.info "Add node #{node} to running jobs"
      with_lock do
        n = del node
        n.user = opt['user']
        n.email = opt['email']
        n.msg  = opt['msg']
        n.from = opt['from']
        # set last job to nil so that the node is picked for immediate update
        n.last = nil
        # set nexted to true so that the node will not be skipped with interval 0
        n.nexted = true
        put n
        jobs.increment if Oxidized.config.next_adds_job?
      end
    end
    alias top next

    # @return [String] node from the head of the array
    def get
      with_lock do
        (self << shift).last
      end
    end

    # @param node node whose index number in Nodes to find
    # @return [Fixnum] index number of node in Nodes
    def find_node_index(node)
      find_index(node) || raise(NodeNotFound, "unable to find '#{node}'")
    end

    # Returns all stored versions of group/node_name
    #
    # Called by oxidized-web
    def version(node_name, group)
      yield_node_output(node_name) do |node, output|
        output.version node, group
      end
    end

    def get_version(node_name, group, oid)
      yield_node_output(node_name) do |node, output|
        output.get_version node, group, oid
      end
    end

    def get_diff(node_name, group, oid1, oid2)
      yield_node_output(node_name) do |node, output|
        output.get_diff node, group, oid1, oid2
      end
    end

    def find_index(node)
      index { |e| [e.name, e.ip].include? node }
    end

    private

    def initialize(opts = {})
      super()
      node = opts.delete :node
      @mutex = Mutex.new # we compete for the nodes with webapi thread
      if (nodes = opts.delete(:nodes))
        replace nodes
      else
        load node
      end
    end

    def with_lock(...)
      @mutex.synchronize(...)
    end

    # Constructs Node objects from +candidates+ (an Array of option hashes) using
    # a thread pool so that DNS lookups run concurrently instead of serially.
    # Nodes whose source options are identical to the existing Node object are
    # reused as-is — no DNS lookup, no object reconstruction.
    # Results preserve the original source ordering.
    def build_nodes_parallel(candidates)
      return [] if candidates.empty?

      # Snapshot existing nodes outside the mutex for delta comparison.
      # A stale read here is harmless: at worst we reconstruct a node unnecessarily.
      existing = each_with_object({}) { |n, h| h[n.name] = n }

      num_threads = [Oxidized.config.node_load_threads || 20, candidates.size].min
      results     = []
      results_mu  = Mutex.new
      queue       = Queue.new
      candidates.each_with_index { |node, i| queue << [i, node] }

      threads = num_threads.times.map do
        Thread.new do
          loop do
            i, node = queue.pop(true)
            existing_node = existing[node[:name]]
            built = if existing_node&.source_opts == node
                      existing_node # unchanged: reuse without DNS or reconstruction
                    else
                      begin
                        Node.new(node)
                      rescue ModelNotFound => e
                        logger.error "node %s raised %s with message '%s'" % [node, e.class, e.message]
                        nil
                      rescue Resolv::ResolvError => e
                        logger.error "node %s is not resolvable, raised %s with message '%s'" \
                                     % [node, e.class, e.message]
                        nil
                      end
                    end
            results_mu.synchronize { results << [i, built] } unless built.nil?
          rescue ThreadError
            break # queue is empty
          end
        end
      end
      threads.each(&:join)

      results.sort_by { |i, _| i }.map { |_, n| n }
    end

    # @param node node which is removed from nodes list
    # @return [Node] deleted node
    def del(node)
      delete_at find_node_index(node)
    end

    # @return [Nodes] list of nodes running now
    def running
      Nodes.new nodes: select { |node| node.running? }
    end

    # @return [Nodes] list of nodes waiting (not running)
    def waiting
      Nodes.new nodes: select { |node| not node.running? }
    end

    # Delta-merges +new_nodes+ into the current list.
    #
    # - Unchanged nodes (same object identity from build_nodes_parallel) keep
    #   their position and all runtime state (last job, stats, running flag, etc.).
    # - Changed nodes (config updated in source) are replaced in-place; last/stats
    #   are carried over so history is not lost.
    # - New nodes (not previously in the list) are appended.
    # - Removed nodes (present in old list but absent from new source) are deleted.
    #
    # The list is then re-sorted by last.end so scheduling priority is preserved.
    def update_nodes(new_nodes)
      new_by_name = new_nodes.each_with_object({}) { |n, h| h[n.name] = n }
      old_by_name = each_with_object({}) { |n, h| h[n.name] = n }

      # Remove nodes that are no longer present in the source
      delete_if { |n| !new_by_name.has_key?(n.name) }

      new_nodes.each do |new_node|
        if (old_node = old_by_name[new_node.name])
          if new_node.equal?(old_node)
            # Identical object reused by build_nodes_parallel — nothing to do,
            # the node is already in the list with all its runtime state intact.
          else
            # Source config changed: carry over job history and replace in list
            new_node.stats = old_node.stats
            new_node.last  = old_node.last
            idx = index { |n| n.name == new_node.name }
            self[idx] = new_node if idx
          end
        else
          push new_node # genuinely new node
        end
      end

      sort_by! { |x| x.last.nil? ? Time.new(0) : x.last.end }
    end

    def yield_node_output(node_name)
      with_lock do
        node = find { |n| n.name == node_name }
        raise(NodeNotFound, "unable to find '#{node_name}'") if node.nil?

        output = node.output.new
        raise NotSupported unless output.respond_to? :fetch

        yield node, output
      end
    end
  end
end
