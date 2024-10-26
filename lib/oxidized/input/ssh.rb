module Oxidized
  module Input
    require 'net/ssh'
    require 'net/ssh/proxy/command'
    require 'timeout'
    require 'oxidized/input/cli'

    # Manages SSH connections to network devices for configuration retrieval.
    #
    # This class extends the Input module and provides methods for connecting
    # to devices, sending commands, and handling authentication.
    class SSH < Input
      # A hash defining exceptions that may be raised during SSH operations.
      RESCUE_FAIL = {
        debug: [
          Net::SSH::Disconnect
        ],
        warn:  [
          RuntimeError,
          Net::SSH::AuthenticationFailed
        ]
      }.freeze
      include Input::CLI

      require 'oxidized/error/noshell'

      # Establishes an SSH connection to the specified node.
      #
      # @param node [Node] The node to connect to for SSH operations.
      # @return [Boolean] True if connection is successful, otherwise raises an error.
      def connect(node)
        @node        = node
        @output      = ''
        @pty_options = { term: "vt100" }
        @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
        @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-ssh", 'w') if Oxidized.config.input.debug?

        Oxidized.logger.debug "lib/oxidized/input/ssh.rb: Connecting to #{@node.name}"
        @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
        unless @exec
          shell_open @ssh
          begin
            login
          rescue Timeout::Error
            raise PromptUndetect, [@output, 'not matching configured prompt', @node.prompt].join(' ')
          end
        end
        connected?
      end

      # Checks if the SSH connection is currently open.
      #
      # @return [Boolean] True if connected, false otherwise.
      def connected?
        @ssh && (not @ssh.closed?)
      end

      # Sends a command to the SSH server.
      #
      # @param cmd [String] The command to execute on the SSH server.
      # @param expect [String] The expected prompt after the command is executed.
      # @return [String] The output from the command execution.
      def cmd(cmd, expect = node.prompt)
        Oxidized.logger.debug "lib/oxidized/input/ssh.rb #{cmd} @ #{node.name} with expect: #{expect.inspect}"
        cmd_output = if @exec
                       @ssh.exec! cmd
                     else
                       cmd_shell(cmd, expect).gsub("\r\n", "\n")
                     end
        # @!visibility private
        # Make sure we return a String
        cmd_output.to_s
      end

      # Sends data to the SSH session.
      #
      # @param data [String] The data to send.
      # @return [void]
      def send(data)
        @ses.send_data data
      end

      # Returns the accumulated output from the SSH session.
      #
      # @!attribute [rw] output
      # @return [String] The output collected during the session.
      attr_reader :output

      # Sets options for the pseudo-terminal.
      #
      # @param hash [Hash] The options to merge into the current pty_options.
      # @return [void]
      def pty_options(hash)
        @pty_options = @pty_options.merge hash
      end

      private

      # Closes the SSH connection and log file if debugging is enabled.
      #
      # @return [void]
      def disconnect
        disconnect_cli
        # @!visibility private
        # if disconnect does not disconnect us, give up after timeout
        Timeout.timeout(Oxidized.config.timeout) { @ssh.loop }
      rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
        # @!visibility private
        # These exceptions are intented and therefore not handled here
      ensure
        @log.close if Oxidized.config.input.debug?
        (@ssh.close rescue true) unless @ssh.closed?
      end

      # Opens a shell on the SSH session.
      #
      # @param ssh [Net::SSH::Connection] The SSH connection object.
      # @return [void]
      def shell_open(ssh)
        @ses = ssh.open_channel do |ch|
          ch.on_data do |_ch, data|
            if Oxidized.config.input.debug?
              @log.print data
              @log.flush
            end
            @output << data
            @output = @node.model.expects @output
          end
          ch.request_pty(@pty_options) do |_ch, success_pty|
            raise Error::NoShell, "Can't get PTY" unless success_pty

            ch.send_channel_request 'shell' do |_ch, success_shell|
              raise Error::NoShell, "Can't get shell" unless success_shell
            end
          end
        end
      end

      # Enables or disables command execution mode.
      #
      # @param state [Boolean] The state of command execution.
      # @return [Boolean, nil] The current execution state or nil if setting.
      def exec(state = nil)
        return nil if vars(:ssh_no_exec)

        state.nil? ? @exec : (@exec = state)
      end

      # Sends a command to the SSH session and waits for an expected response.
      #
      # @param cmd [String] The command to send.
      # @param expect_re [Regexp] The expected response regex.
      # @return [String] The output received after sending the command.
      def cmd_shell(cmd, expect_re)
        @output = ''
        @ses.send_data cmd + "\n"
        @ses.process
        expect expect_re if expect_re
        @output
      end

      # Waits for a matching response based on the provided regex patterns.
      #
      # @param regexps [Regexp] The expected regex patterns.
      # @return [Regexp, nil] The matched regex if found, otherwise nil.
      def expect(*regexps)
        regexps = [regexps].flatten
        Oxidized.logger.debug "lib/oxidized/input/ssh.rb: expecting #{regexps.inspect} at #{node.name}"
        Timeout.timeout(Oxidized.config.timeout) do
          @ssh.loop(0.1) do
            sleep 0.1
            match = regexps.find { |regexp| @output.match regexp }
            return match if match

            true
          end
        end
      end

      # Creates SSH options based on the node's configuration and Oxidized settings.
      #
      # @return [Hash] The SSH options for the connection.
      def make_ssh_opts
        secure = Oxidized.config.input.ssh.secure?
        ssh_opts = {
          number_of_password_prompts:      0,
          keepalive:                       vars(:ssh_no_keepalive) ? false : true,
          verify_host_key:                 secure ? :always : :never,
          append_all_supported_algorithms: true,
          password:                        @node.auth[:password],
          timeout:                         Oxidized.config.timeout,
          port:                            (vars(:ssh_port) || 22).to_i,
          forward_agent:                   false
        }

        auth_methods = vars(:auth_methods) || %w[none publickey password]
        ssh_opts[:auth_methods] = auth_methods
        Oxidized.logger.debug "AUTH METHODS::#{auth_methods}"

        ssh_opts[:proxy] = make_ssh_proxy_command(vars(:ssh_proxy), vars(:ssh_proxy_port), secure) if vars(:ssh_proxy)

        ssh_opts[:keys]       = [vars(:ssh_keys)].flatten           if vars(:ssh_keys)
        ssh_opts[:kex]        = vars(:ssh_kex).split(/,\s*/)        if vars(:ssh_kex)
        ssh_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)
        ssh_opts[:host_key]   = vars(:ssh_host_key).split(/,\s*/)   if vars(:ssh_host_key)
        ssh_opts[:hmac]       = vars(:ssh_hmac).split(/,\s*/)       if vars(:ssh_hmac)

        if Oxidized.config.input.debug?
          ssh_opts[:logger]  = Oxidized.logger
          ssh_opts[:verbose] = Logger::DEBUG
        end

        ssh_opts
      end

      # Creates an SSH proxy command for connecting through a proxy host.
      #
      # @param proxy_host [String] The proxy host to connect through.
      # @param proxy_port [Integer] The port of the proxy host.
      # @param secure [Boolean] Indicates if the connection is secure.
      # @return [Net::SSH::Proxy::Command, nil] The proxy command or nil if not applicable.
      def make_ssh_proxy_command(proxy_host, proxy_port, secure)
        return nil unless !proxy_host.nil? && !proxy_host.empty?

        proxy_command =  "ssh "
        proxy_command += "-o StrictHostKeyChecking=no " unless secure
        proxy_command += "-p #{proxy_port} "            if proxy_port
        proxy_command += "#{proxy_host} -W [%h]:%p"
        Net::SSH::Proxy::Command.new(proxy_command)
      end
    end
  end
end
