module Oxidized
  class Job < Thread
    attr_reader :start, :end, :status, :time, :node, :config
    def initialize(node)
      @node         = node
      @start        = Time.now.utc
      super do
        Oxidized.logger.debug "lib/oxidized/job.rb: Starting fetching process for #{@node.name} at #{Time.now.utc}"
        if node.is_lockedout?
          Oxidized.logger.info "lib/oxidized/job.rb: Node [#{@node.name}] IP [#{@node.ip}] is locked. Skipping."
          # Fake these up a bit
          @status = :locked
          @config = nil
        else
          @status, @config = @node.run
        end
        @end             = Time.now.utc
        @time            = @end - @start
        Oxidized.logger.debug "lib/oxidized/job.rb: Config fetched for #{@node.name} at #{@end}"
      end
    end
  end
end
