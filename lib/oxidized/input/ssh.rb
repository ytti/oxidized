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
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-ssh", 'w') if Oxidized.config.input.debug?

      wrapper_opts = {
        :port 			=> vars(:ssh_port) || 22,
        :password 		=> @node.auth[:password], :timeout => Oxidized.config.timeout,
        :paranoid	 	=> Oxidized.config.input.ssh.secure,
        :auth_methods   	=> %w(none publickey password keyboard-interactive),
        :number_of_password_prompts => 0,
        :proxy 			=> vars(:ssh_proxy),
        :logger 		=> Oxidized.logger,
	:prompt 		=> node.prompt,
	:exec 			=> @exec,
	:ip 			=> @node.ip,
        :username		=> @node.auth[:username],
	:username_prompt	=> username,
	:password_prompt	=> password,
	:pty_options		=> {term: "vt100" },
	:expectation_handler    => [@node.model, :expects]
      }

      wrapper_opts[:keys] = vars(:ssh_keys).is_a?(Array) ? vars(:ssh_keys) : [vars(:ssh_keys)] if vars(:ssh_keys)
      wrapper_opts[:kex]  = vars(:ssh_kex).split(/,\s*/) if vars(:ssh_kex)
      wrapper_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)

      Oxidized.logger.debug "lib/oxidized/input/ssh.rb: Connecting to #{@node.name}"

      @ssh = Oxidized::SSHWrapper.new(wrapper_opts)
      @ssh.start

      connected?
    end

    def connected?
      @ssh.connection and not @ssh.connection.closed?
    end

    def cmd cmd, expect=node.prompt
	msg = "lib/oxidized/input/ssh.rb #{cmd} @ #{node.name}"
        msg << "with expect #{expect.inspect}" unless @exec
	Oxidized.logger.debug msg
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
      @ssh.pty_options = @pty_options
    end

    private

    def disconnect
      disconnect_cli
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
    end

    def exec state=nil
      state == nil ? @exec : (@exec=state) unless vars :ssh_no_exec
    end

  end
end
