module Oxidized
  # Job class represents an individual job for fetching configuration from a node.
  # It inherits from `Thread` to run the job in a separate thread.
  class Job < Thread
    # @!attribute [r] start
    #   @return [Time] the start time of the job
    attr_reader :start

    # @!attribute [r] end
    #   @return [Time] the end time of the job
    attr_reader :end

    # @!attribute [r] status
    #   @return [Symbol] the status of the fetch operation (:success, :failure)
    attr_reader :status

    # @!attribute [r] time
    #   @return [Float] the time taken to complete the job (in seconds)
    attr_reader :time

    # @!attribute [r] node
    #   @return [Node] the node for which the configuration is being fetched
    attr_reader :node

    # @!attribute [r] config
    #   @return [String] the configuration fetched from the node
    attr_reader :config

    # Initializes a new job for fetching a node's configuration.
    #
    # @param node [Node] the node for which the configuration is fetched.
    def initialize(node)
      @node         = node
      @start        = Time.now.utc
      super do
        Oxidized.logger.debug "lib/oxidized/job.rb: Starting fetching process for #{@node.name} at #{Time.now.utc}"
        @status, @config = @node.run
        @end             = Time.now.utc
        @time            = @end - @start
        Oxidized.logger.debug "lib/oxidized/job.rb: Config fetched for #{@node.name} at #{@end}"
      end
    end
  end
end
