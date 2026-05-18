module Oxidized
  class DebugText
    include SemanticLogger::Loggable

    def initialize(config_debug, node, input_name)
      return unless config_debug == true ||
                    (config_debug.is_a?(String) && config_debug.downcase.include?('text'))

      @log = File.open(logfile(node, input_name), 'w')
    end

    # Separate method to ease unit tests
    def logfile(node, input_name)
      timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
      file = Oxidized::Config::LOG + "/#{node&.ip}-#{input_name}-#{timestamp}.txt"
      logger.debug "Writing I/O Debugging to #{file}"
      file
    end

    def send_data(data)
      return unless @log

      @log.puts "sent cmd #{data.dump}"
      @log.flush
    end

    def receive_data(data)
      return unless @log

      @log.puts "received #{data.dump}"
      @log.flush
    end

    def close
      return unless @log

      @log.close
    end
  end
end
