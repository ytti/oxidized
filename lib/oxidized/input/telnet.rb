module Oxidized
  module Input
    require 'net/telnet'
    require 'oxidized/input/cli'

    # Manages Telnet connections to network devices for command execution.
    #
    # This class extends the Input module and provides methods for connecting
    # to devices, executing commands via Telnet, and handling authentication.
    class Telnet < Input
      # A hash defining exceptions that may be raised during Telnet operations.
      RESCUE_FAIL = {}.freeze
      include Input::CLI

      # @!attribute [rw] telnet
      # @return [Net::Telnet] The Telnet session object.
      attr_reader :telnet

      # Establishes a Telnet connection to the specified node.
      #
      # @param node [Node] The node to connect to for Telnet operations.
      # @return [Boolean] True if connection is successful, otherwise raises an error.
      def connect(node)
        @node    = node
        @timeout = Oxidized.config.timeout
        @node.model.cfg['telnet'].each { |cb| instance_exec(&cb) }
        @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-telnet", 'w') if Oxidized.config.input.debug?
        port = vars(:telnet_port) || 23

        telnet_opts = {
          'Host'    => @node.ip,
          'Port'    => port.to_i,
          'Timeout' => @timeout,
          'Model'   => @node.model,
          'Log'     => @log
        }

        @telnet = Net::Telnet.new telnet_opts
        begin
          login
        rescue Timeout::Error
          raise PromptUndetect, ['unable to detect prompt:', @node.prompt].join(' ')
        end
        connected?
      end

      # Checks if the Telnet connection is currently open.
      #
      # @return [Boolean] True if connected, false otherwise.
      def connected?
        @telnet && (not @telnet.sock.closed?)
      end

      # Sends a command string to the Telnet session and expects a response.
      #
      # @param cmd_str [String] The command string to send.
      # @param expect [Regexp, String] The expected prompt or output to match against.
      # @return [String] The output received from the command.
      def cmd(cmd_str, expect = @node.prompt)
        Oxidized.logger.debug "Telnet: #{cmd_str} @#{@node.name}"
        return send(cmd_str + "\r\n") unless expect

        # @!visibility private
        # create a string to be passed to oxidized_expect and modified _there_
        # default to a single space so it shouldn't be coerced to nil by any models.
        out = String(' ')
        @telnet.puts(cmd_str)
        @telnet.oxidized_expect(timeout: @timeout, expect: expect, out: out)
        out
      end

      # Writes data to the Telnet session.
      #
      # @param data [String] The data to send.
      # @return [void]
      def send(data)
        @telnet.write data
      end

      # Returns the output received from the Telnet session.
      #
      # @return [String] The output from the Telnet session.
      def output
        @telnet.output
      end

      private

      # Waits for a specific regular expression to appear in the Telnet output.
      #
      # @param regex [Regexp] The regular expression to expect.
      # @return [Regexp, nil] The matched expression if found, otherwise nil.
      def expect(regex)
        @telnet.oxidized_expect expect: regex, timeout: @timeout
      end

      # Closes the Telnet connection and log file if debugging is enabled.
      #
      # @return [void]
      def disconnect
        disconnect_cli
        @telnet.close
      rescue Errno::ECONNRESET, IOError
        # @!visibility private
        # This exception is intented and therefore not handled here
      ensure
        @log.close if Oxidized.config.input.debug?
        (@telnet.close rescue true) unless @telnet.sock.closed?
      end
    end
  end

  # Net module
  #
  # The Net module provides classes for performing network operations,
  # including HTTP, FTP, and other protocols.
  #
  # This module serves as a namespace for various networking classes
  # and methods, facilitating interactions with network resources.
  module Net
    # This class provides an interface for interacting with Telnet sessions.
    # It facilitates communication with network devices using the Telnet protocol.
    #
    # The class extends functionality specific to Oxidized, allowing for custom
    # handling of Telnet commands and responses.
    class Telnet
      # @!visibility private
      ## how to do this, without redefining the whole damn thing
      ## FIXME: we also need output (not sure I'm going to support this)

      # @!attribute [rw] output
      #   @return [Time] the Telnet session output
      attr_reader :output

      # Waits for expected output in the Telnet session.
      #
      # @param options [Hash] Options for the expect operation.
      # @option options [Regexp, String] :expect The expected output to match.
      # @option options [Integer] :timeout The maximum wait time.
      # @return [Regexp, nil] The matched expression if found, otherwise nil.
      def oxidized_expect(options) ## rubocop:disable Metrics/PerceivedComplexity
        model    = @options["Model"]
        @log     = @options["Log"]

        expects  = [options[:expect]].flatten
        time_out = options[:timeout] || @options["Timeout"] || Oxidized.config.timeout?

        Timeout.timeout(time_out) do
          line = ""
          rest = ""
          buf  = ""
          loop do
            c = @sock.readpartial(1024 * 1024)
            @output = c
            c = rest + c

            if Integer(c.rindex(/#{IAC}#{SE}/no) || 0) <
               Integer(c.rindex(/#{IAC}#{SB}/no) || 0)
              buf = preprocess(c[0...c.rindex(/#{IAC}#{SB}/no)])
              rest = c[c.rindex(/#{IAC}#{SB}/no)..-1]
            elsif (pt = c.rindex(/#{IAC}[^#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]?\z/no) ||
                       c.rindex(/\r\z/no))
              buf = preprocess(c[0...pt])
              rest = c[pt..-1]
            else
              buf = preprocess(c)
              rest = ''
            end
            if Oxidized.config.input.debug?
              @log.print buf
              @log.flush
            end
            line += buf
            line = model.expects line
            # @!visibility private
            # match is a regexp object. we need to return that for logins to work.
            match = expects.find { |re| line.match re }
            # @!visibility private
            # stomp on the out string object if we have one. (thus we were called by cmd?)
            options[:out]&.replace(line)
            return match if match
          end
        end
      end
    end
  end
end
