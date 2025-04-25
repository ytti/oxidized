module Oxidized
  class Job < Thread
    include SemanticLogger::Loggable

    attr_reader :start, :end, :status, :time, :node, :config

    def initialize(node)
      @node         = node
      @start        = Time.now.utc
      super do
        logger.debug "lib/oxidized/job.rb: Starting fetching process for #{@node.name} at #{Time.now.utc}"
        @status, @config = @node.run
        @end             = Time.now.utc
        @time            = @end - @start
        logger.debug "lib/oxidized/job.rb: Config fetched for #{@node.name} at #{@end}"
      end
    end
  end
end
