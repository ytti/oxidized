module Oxidized
  require 'net/ssh'
  require 'net/ssh/proxy/command'
  require 'timeout'
  require 'oxidized/input/cli'
  class SSH < Input
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
    class NoShell < OxidizedError; end

    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node        = node
      @output      = String.new('')
      @pty_options = { term: "vt100" }
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      if Oxidized.config.input.debug?
        logfile = Oxidized::Config::LOG + "/#{@node.ip}-ssh"
        @log = File.open(logfile, 'w')
        logger.debug "I/O Debuging to #{logfile}"
      end

      logger.debug "Connecting to #{@node.name}"
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

    def connected?
      @ssh && (not @ssh.closed?)
    end

    def cmd(cmd, expect = node.prompt)
      logger.debug "Sending '#{cmd.dump}' @ #{node.name} with expect: #{expect.inspect}"
      if Oxidized.config.input.debug?
        @log.puts "sent cmd #{@exec ? cmd.dump : (cmd + newline).dump}"
        @log.flush
      end
      cmd_output = if @exec
                     @ssh.exec! cmd
                   else
                     cmd_shell(cmd, expect).gsub("\r\n", "\n")
                   end
      # Make sure we return a String
      cmd_output.to_s
    end

    def send(data)
      if Oxidized.config.input.debug?
        @log.puts "sent data #{data.dump}"
        @log.flush
      end
      @ses.send_data data
    end

    attr_reader :output

    def pty_options(hash)
      @pty_options = @pty_options.merge hash
    end

    private

    def disconnect
      disconnect_cli
      # if disconnect does not disconnect us, give up after timeout
      Timeout.timeout(Oxidized.config.timeout) { @ssh.loop }
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError => e
      logger.debug 'The other side closed the connection while ' \
                   "disconnecting, raising #{e.class} with #{e.message}"
    rescue Timeout::Error
      logger.debug "#{@node.name} timed out while disconnecting"
    ensure
      @log.close if Oxidized.config.input.debug?
      (@ssh.close rescue true) unless @ssh.closed?
    end

    def shell_open(ssh)
      @ses = ssh.open_channel do |ch|
        ch.on_data do |_ch, data|
          if Oxidized.config.input.debug?
            @log.puts "received #{data.dump}"
            @log.flush
          end
          @output << data
          @output = @node.model.expects @output
        end
        ch.request_pty(@pty_options) do |_ch, success_pty|
          raise NoShell, "Can't get PTY" unless success_pty

          ch.send_channel_request 'shell' do |_ch, success_shell|
            raise NoShell, "Can't get shell" unless success_shell
          end
        end
      end
    end

    def exec(state = nil)
      return nil if vars(:ssh_no_exec)

      state.nil? ? @exec : (@exec = state)
    end

    def cmd_shell(cmd, expect_re)
      @output = String.new('')
      @ses.send_data cmd + newline
      @ses.process
      expect expect_re if expect_re
      @output
    end

    def expect(*regexps)
      regexps = [regexps].flatten
      logger.debug "Expecting #{regexps.inspect} at #{node.name}"
      Timeout.timeout(Oxidized.config.timeout) do
        @ssh.loop(0.1) do
          sleep 0.1
          match = regexps.find { |regexp| @output.match regexp }
          return match if match

          true
        end
      end
    end

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
      logger.debug "AUTH METHODS::#{auth_methods}"

      ssh_opts[:proxy] = make_ssh_proxy_command(vars(:ssh_proxy), vars(:ssh_proxy_port), secure) if vars(:ssh_proxy)

      ssh_opts[:keys]       = [vars(:ssh_keys)].flatten           if vars(:ssh_keys)
      ssh_opts[:kex]        = vars(:ssh_kex).split(/,\s*/)        if vars(:ssh_kex)
      ssh_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)
      ssh_opts[:host_key]   = vars(:ssh_host_key).split(/,\s*/)   if vars(:ssh_host_key)
      ssh_opts[:hmac]       = vars(:ssh_hmac).split(/,\s*/)       if vars(:ssh_hmac)

      # Use our logger for Net:SSH
      ssh_logger = SemanticLogger[Net::SSH]
      ssh_logger.level = Oxidized.config.input.debug? ? :debug : :fatal
      ssh_opts[:logger] = ssh_logger

      ssh_opts
    end

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
