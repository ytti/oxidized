module Oxidized
  require 'net/ssh'
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
      @node       = node
      @output     = ''
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      secure = CFG.input.ssh.secure
      @log = File.open(CFG.input.debug?.to_s + '-ssh', 'w') if CFG.input.debug?
      @ssh = Net::SSH.start @node.ip, @node.auth[:username],
                            :password => @node.auth[:password], :timeout => CFG.timeout,
                            :paranoid => secure,
                            :auth_methods => %w(none publickey password),
                            :number_of_password_prompts => 0
      unless @exec
        shell_open @ssh
        begin
          @username ? shell_login : expect(@node.prompt)
        rescue Timeout::Error
          raise PromptUndetect, [ @output, 'not matching configured prompt', @node.prompt ].join(' ')
        end
      end
      connected?
    end

    def connected?
      @ssh and not @ssh.closed?
    end

    def cmd cmd, expect=@node.prompt
      Log.debug "SSH: #{cmd} @ #{@node.name}"
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

    private

    def disconnect
      disconnect_cli
      # if disconnect does not disconnect us, give up after timeout
      Timeout::timeout(CFG.timeout) { @ssh.loop }
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
    ensure
      @log.close if CFG.input.debug?
      (@ssh.close rescue true) unless @ssh.closed?
    end

    def shell_open ssh
      @ses = ssh.open_channel do |ch|
        ch.on_data do |_ch, data|
          @log.print data if CFG.input.debug?
          @output << data
          @output = @node.model.expects @output
        end
        ch.request_pty do |_ch, success_pty|
          raise NoShell, "Can't get PTY" unless success_pty
          ch.send_channel_request 'shell' do |_ch, success_shell|
            raise NoShell, "Can't get shell" unless success_shell
          end
        end
      end
    end

    # Cisco WCS has extremely dubious SSH implementation, SSH auth is always
    # success, it always opens shell and then run auth in shell. I guess
    # they'll never support exec() :)
    def shell_login
      expect username
      cmd @node.auth[:username], password
      cmd @node.auth[:password]
    end

    def exec state=nil
      state == nil ? @exec : (@exec=state)
    end

    def cmd_shell(cmd, expect_re)
      @output = ''
      @ses.send_data cmd + "\n"
      @ses.process
      expect expect_re if expect_re
      @output
    end

    def expect regexp
      Timeout::timeout(CFG.timeout) do
        @ssh.loop(0.1) do
          sleep 0.1
          not @output.match regexp
        end
      end
    end

  end
end
