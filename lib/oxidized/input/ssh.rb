module Oxidized
  require 'net/ssh'
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
    include CLI
    class NoShell < StandardError; end

    def connect node
      @node       = node
      @output     = ''
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      secure = CFG.input[:ssh][:secure]
      @ssh = Net::SSH.start @node.ip, @node.auth[:username],
                            :password => @node.auth[:password], :timeout => CFG.timeout,
                            :paranoid => secure
      open_shell @ssh unless @exec
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
      begin
        disconnect_cli
        @ssh.loop
        @ssh.close if not @ssh.closed?
      rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
      end
    end

    def open_shell ssh
      @ses = ssh.open_channel do |ch|
        ch.on_data do |ch, data|
          @output << data
          @output = @node.model.expects @output
        end
        ch.request_pty do |ch, success|
          raise NoShell, "Can't get PTY" unless success
          ch.send_channel_request 'shell' do |ch, success|
            raise NoShell, "Can't get shell" unless success
          end
        end
      end
      expect @node.prompt
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
      @ssh.loop(0.1) do
        sleep 0.1
        not @output.match regexp
      end
    end

  end
end
