module Oxidized
  require 'net/ssh'
  require 'oxidized/sshwrapper'
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
      ssh_opts[:ip] = @node.ip
      ssh_opts[:username] = @node.auth[:username]
      ssh_opts[:debug] = false
      ssh_opts[:exec] = @exec
      ssh_opts[:logger] = Oxidized.logger
      ssh_opts[:prompt] = node.prompt
      Oxidized.logger.debug "lib/oxidized/input/ssh.rb: Connecting to #{@node.name}"
      @ssh = Oxidized::SSHWrapper.new(ssh_opts)
      @ssh.start
      connected?
    end

    def connected?
      @ssh.connection and not @ssh.connection.closed?
    end

    def cmd cmd, expect=node.prompt
	msg = "lib/oxidized/input/ssh.rb #{cmd} @ #{node.name}"
        msg << "with expect #{expect.inspect}" if @exec
        @ssh.exec! cmd
    end

    def send data
      @ses.send_data data
    end

    def output
      @ssh.output
    end

    def pty_options hash
      @pty_options = @pty_options.merge hash
    end

    private

    def disconnect
      disconnect_cli
      # if disconnect does not disconnect us, give up after timeout
      Timeout::timeout(Oxidized.config.timeout) { @ssh.connection.loop }
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
      (@ssh.close rescue true) unless @ssh.connected?
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

  end
end
