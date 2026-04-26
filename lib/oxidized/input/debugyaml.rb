module Oxidized
  class DebugYAML
    include SemanticLogger::Loggable

    def initialize(config_debug, node, input_name)
      return unless config_debug == true ||
                    (config_debug.is_a?(String) && config_debug.downcase.include?('yaml'))

      @log = File.open(logfile(node, input_name), 'w')

      @partial_line = false
      @first_line = true
      @commands_started = false

      @log.puts '---'
      @log.puts 'init_prompt: |-'
      @log.flush
    end

    # Separate method to ease unit tests
    def logfile(node, input_name)
      timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
      file = Oxidized::Config::LOG + "/#{node&.ip}-#{input_name}-#{timestamp}.yaml"
      logger.debug "Writing YAML Simulation to #{file}"
      file
    end

    def send_data(data)
      return unless @log

      @log.puts
      @log.puts 'commands:' unless @commands_started
      @log.puts "  - #{data.dump}: |-"
      @first_line = true
      @partial_line = false
      @commands_started = true
      @log.flush
    end

    def receive_data(data)
      return unless @log

      lines = data.split("\n", -1)

      lines.each_with_index do |line, idx|
        is_last = idx == lines.length - 1
        full_line = is_last ? (data[-1] == "\n") : true
        # Escape line and strip surrounding double quotes
        line = line.dump[1..-2]
        if @first_line
          # Make sure the leading space of the first line (if present)
          # is coded with \0x20 or YAML block scalars won't work
          line.sub!(/^ /, '\x20')
          @first_line = false
        end

        # Make sure trailing white spaces are coded with \0x20
        line.gsub!(/ $/, '\x20')

        output = @partial_line ? line : ('      ' + line)
        @partial_line = false

        if full_line
          @log.puts output
        else
          @log.write output
        end
      end

      @partial_line = data[-1] != "\n"

      @log.flush
    end

    def close
      return unless @log

      @log.close
    end
  end
end
