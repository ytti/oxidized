module Oxidized
  class Job < Thread
    include SemanticLogger::Loggable

    attr_reader :start, :end, :status, :time, :node, :config

    def initialize(node)
      @node = node
      @start = Time.now.utc
      self.name = "Job '#{@node.name}'"
      super do
        logger.debug "Starting fetching process for #{@node.name}"
        begin
          Timeout.timeout(Oxidized.config.timelimit) do
            @status, @config = @node.run
          end
          logger.debug "Config fetched for #{@node.name}"
        rescue Timeout::Error
          logger.warn "Job timelimit reached for #{@node.name}"
          @status = :timelimit
        ensure
          @end  = Time.now.utc
          @time = @end - @start
        end
      end
    end
  end
end
