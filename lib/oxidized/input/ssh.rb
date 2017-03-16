module Oxidized
  require 'net/ssh'
  require 'net/ssh/proxy/command'
  require 'timeout'
  require 'oxidized/input/cli'
  class SSH < Input
    RescueFail = {
      :debug => [
        Net::SSH::Disconnect,
      ],
      :warn => [
        RuntimeError,
        Net::SSH::AuthenticationFailed,
      ],
    }
    include Input::CLI
    class NoShell < OxidizedError; end

    def connect node
      @node        = node
      @output      = ''
      @pty_options = { term: "vt100" }
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      secure = Oxidized.config.input.ssh.secure
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-ssh", 'w') if Oxidized.config.input.debug?
      port = vars(:ssh_port) || 22
      if proxy_host = vars(:ssh_proxy)
        proxy_command =  "ssh "
        proxy_command += "-o StrictHostKeyChecking=no " unless secure
        proxy_command += "#{proxy_host} -W %h:%p"
        proxy =  Net::SSH::Proxy::Command.new(proxy_command)
      end
      ssh_opts = {
        :port => port.to_i,
        :password => @node.auth[:password], :timeout => Oxidized.config.timeout,
        :paranoid => secure,
        :auth_methods => %w(none publickey password keyboard-interactive),
        :number_of_password_prompts => 0,
        :proxy => proxy,
      }
      ssh_opts[:keys] = vars(:ssh_keys).is_a?(Array) ? vars(:ssh_keys) : [vars(:ssh_keys)] if vars(:ssh_keys)
      ssh_opts[:kex]  = vars(:ssh_kex).split(/,\s*/) if vars(:ssh_kex)
      ssh_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)

      Oxidized.logger.debug "lib/oxidized/input/ssh.rb: Connecting to #{@node.name}"
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], ssh_opts)
      unless @exec
        shell_open @ssh
        begin
          login
        rescue Timeout::Error
          raise PromptUndetect, [ @output, 'not matching configured prompt', @node.prompt ].join(' ')
        end
      end
      connected?
    end

    def connected?
      @ssh and not @ssh.closed?
    end

    def cmd cmd, expect=node.prompt
      Oxidized.logger.debug "lib/oxidized/input/ssh.rb #{cmd} @ #{node.name} with expect: #{expect.inspect}"
      if @exec
        @ssh.exec! cmd
      else
        cmd_shell(cmd, expect).gsub(/\r\n/, "\n")
      end
    end

    def send data
      @ses.send_data data
    end

    def output
      @output
    end

    def pty_options hash
      @pty_options = @pty_options.merge hash
    end

    private

    def disconnect
      disconnect_cli
      # if disconnect does not disconnect us, give up after timeout
      Timeout::timeout(Oxidized.config.timeout) { @ssh.loop }
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
      (@ssh.close rescue true) unless @ssh.closed?
    end

    def shell_open ssh
      @ses = ssh.open_channel do |ch|
        ch.on_data do |_ch, data|
          if Oxidized.config.input.debug?
            @log.print data
            @log.fsync
          end
          @output << data
          @output = @node.model.expects @output
        end
        ch.request_pty (@pty_options) do |_ch, success_pty|
          raise NoShell, "Can't get PTY" unless success_pty
          ch.send_channel_request 'shell' do |_ch, success_shell|
            raise NoShell, "Can't get shell" unless success_shell
          end
        end
      end
    end

    # some models have SSH auth or terminal auth based on version of code
    # if SSH is configured for terminal auth, we'll still try to detect prompt
    def login
      if @username
        match = expect username, @node.prompt
        if match == username
          cmd @node.auth[:username], password
          cmd @node.auth[:password]
        end
      else
        expect @node.prompt
      end
    end

    def exec state=nil
      state == nil ? @exec : (@exec=state) unless vars :ssh_no_exec
    end

    def cmd_shell(cmd, expect_re)
      @output = ''
      @ses.send_data cmd + "\n"
      @ses.process
      expect expect_re if expect_re
      @output
    end

    def expect *regexps
      regexps = [regexps].flatten
      Oxidized.logger.debug "lib/oxidized/input/ssh.rb: expecting #{regexps.inspect} at #{node.name}"
      Timeout::timeout(Oxidized.config.timeout) do
        @ssh.loop(0.1) do
          sleep 0.1
          match = regexps.find { |regexp| @output.match regexp }
          return match if match
          true
        end
      end
    end

  end
end
