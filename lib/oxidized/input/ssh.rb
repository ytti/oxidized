module Oxidized
  require 'net/ssh'
  require 'net/ssh/proxy/command'
  require 'timeout'
  require 'oxidized/input/cli'
  class SSH < Input
    RescueFail = {
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

    def connect(node)
      @node        = node
      @output      = ''
      @pty_options = { term: "vt100" }
      @node.model.cfg['ssh'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-ssh", 'w') if Oxidized.config.input.debug?

      Oxidized.logger.debug "lib/oxidized/input/ssh.rb: Connecting to #{@node.name}"
	  # Check if cisco_jumphost has been defined in the oxidized/config file. If it isn't defined then the normal net::SSH.start method will be called
      if (@node.vars[:cisco_jumphost])
        @ssh = Net::SSH.start(@node.vars[:cisco_jumphost], @node.auth[:username], :append_all_supported_algorithms => true)
      else
        @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      end
      unless @exec
	    # Check if a vrfname is defined in oxidized/config. If it is defined then the proxy will use vrf-vpn. if it isn't defined then it will proxy over a normal connection
        if (@node.vars[:vrfname] != '')
		  # Check which protocol is used. This variable must be defined in oxidized/config if cisco_jumphost is defined.
          if (@node.vars[:protocol] == 'ssh')
            vrf_ssh_shell_open @ssh
          elsif (@node.vars[:protocol] == 'telnet')
            vrf_telnet_shell_open @ssh
          end
          begin
            login
          rescue Timeout::Error
            raise PromptUndetect, [@output, 'not matching configured prompt', @node.prompt].join(' ')
          end
        elsif (@node.vars[:vrfname] == '' and @node.vars[:cisco_jumphost] != '')
		  # Check which protocol is used. This variable must be defined in oxidized/config if cisco_jumphost is defined.
          if (@node.vars[:protocol] == 'ssh')
            proxy_ssh_shell_open @ssh
          elsif (@node.vars[:protocol] == 'telnet')
            proxy_telnet_shell_open @ssh
          end
          begin
            login
          rescue Timeout::Error
            raise PromptUndetect, [@output, 'not matching configured prompt', @node.prompt].join(' ')
          end
        else
          shell_open @ssh
          begin
            login
          rescue Timeout::Error
            raise PromptUndetect, [@output, 'not matching configured prompt', @node.prompt].join(' ')
          end
        end
      end
      connected?
    end

    def connected?
      @ssh && (not @ssh.closed?)
    end

    def cmd(cmd, expect = node.prompt)
      Oxidized.logger.debug "lib/oxidized/input/ssh.rb #{cmd} @ #{node.name} with expect: #{expect.inspect}"
      if @exec
        @ssh.exec! cmd
      else
        cmd_shell(cmd, expect).gsub(/\r\n/, "\n")
      end
    end

    def send(data)
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
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
      (@ssh.close rescue true) unless @ssh.closed?
    end

    def vrf_ssh_shell_open(ssh)
      @ses = ssh.open_channel do |ch|
	    # Execute the command that will initialize the proxy ssh over vrf
        ch.exec "ssh -vrf #{node.vars[:vrfname]} -l #{node.vars[:cisco_proxy_user]} #{node.ip}" do |ch, success|
          raise "could not execute command" unless success
          do_loop = true;
          ch.on_data do |_ch, data|
            if Oxidized.config.input.debug?
              @log.print data
              @log.flush
            end
            @output << data
            @output = @node.model.expects @output
            # Check for password prompt. If the router asks for a password then the password will be send
            if data =~ /Password: / && do_loop
              _ch.send_data("#{node.vars[:cisco_proxy_pass]}\n")
              do_loop = false
            end

          end
        end
      end
    end

    # Execute the command that will initialize the proxy telnet over vrf
    def vrf_telnet_shell_open(ssh)
      @ses = ssh.open_channel do |ch|
        ch.exec "telnet #{node.ip} /vrf #{node.vars[:vrfname]}" do |ch, success|
          raise "could not execute command" unless success
          do_loop0 = true;
          do_loop1 = true;
          ch.on_data do |_ch, data|
            if Oxidized.config.input.debug?
              @log.print data
              @log.flush
            end
            @output << data
            @output = @node.model.expects @output

            # Check for username prompt. If the router asks for a username then the username will be send
            if data =~ /Username: / && do_loop0
              _ch.send_data("#{node.vars[:cisco_proxy_user]}\n")
              do_loop0 = false
            end
			# Check for password prompt. If the router asks for a password then the password will be send
            if data =~ /Password: / && do_loop1
              _ch.send_data("#{node.vars[:cisco_proxy_pass]}\n")
              do_loop1 = false
            end

          end
        end
      end
    end

    # Execute the command that will initialize the proxy ssh over a normal connection
    def proxy_ssh_shell_open(ssh)
      @ses = ssh.open_channel do |ch|
        ch.exec "ssh -l #{node.vars[:cisco_proxy_user]} #{node.ip}" do |ch, success|
          raise "could not execute command" unless success
          do_loop0 = true;
          ch.on_data do |_ch, data|
            if Oxidized.config.input.debug?
              @log.print data
              @log.flush
            end
            @output << data
            @output = @node.model.expects @output

            # Check for password prompt. If the router asks for a password then the password will be send
            if data =~ /Password: / && do_loop1
              _ch.send_data("#{node.vars[:cisco_proxy_pass]}\n")
              do_loop1 = false
            end

          end
        end
      end
    end

    # Execute the command that will initialize the proxy telnet over a normal connection
    def proxy_telnet_shell_open(ssh)
      @ses = ssh.open_channel do |ch|
        ch.exec "telnet #{node.ip}" do |ch, success|
          raise "could not execute command" unless success
          do_loop0 = true;
          do_loop1 = true;
          ch.on_data do |_ch, data|
            if Oxidized.config.input.debug?
              @log.print data
              @log.flush
            end
            @output << data
            @output = @node.model.expects @output

            # Check for username prompt. If the router asks for a username then the username will be send
            if data =~ /Username: / && do_loop0
              _ch.send_data("#{node.vars[:cisco_proxy_user]}\n")
              do_loop0 = false
            end
			# Check for password prompt. If the router asks for a password then the password will be send
            if data =~ /Password: / && do_loop1
              _ch.send_data("#{node.vars[:cisco_proxy_pass]}\n")
              do_loop1 = false
            end

          end
        end
      end
    end


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
      @output = ''
      @ses.send_data cmd + "\n"
      @ses.process
      expect expect_re if expect_re
      @output
    end

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

    def make_ssh_opts
      secure = Oxidized.config.input.ssh.secure?
      ssh_opts = {
        number_of_password_prompts: 0,
        keepalive:                  vars(:ssh_no_keepalive) ? false : true,
        verify_host_key:            secure ? :always : :never,
        password:                   @node.auth[:password],
        timeout:                    Oxidized.config.timeout,
        port:                       (vars(:ssh_port) || 22).to_i
      }

      auth_methods = vars(:auth_methods) || %w[none publickey password]
      ssh_opts[:auth_methods] = auth_methods
      Oxidized.logger.debug "AUTH METHODS::#{auth_methods}"

      if (proxy_host = vars(:ssh_proxy))
        proxy_command =  "ssh "
        proxy_command += "-o StrictHostKeyChecking=no " unless secure
        if (proxy_port = vars(:ssh_proxy_port))
          proxy_command += "-p #{proxy_port} "
        end
        proxy_command += "#{proxy_host} -W %h:%p"

        proxy = Net::SSH::Proxy::Command.new(proxy_command)
        ssh_opts[:proxy] = proxy
      end

      ssh_opts[:keys]       = [vars(:ssh_keys)].flatten if vars(:ssh_keys)
      ssh_opts[:kex]        = vars(:ssh_kex).split(/,\s*/) if vars(:ssh_kex)
      ssh_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)
      ssh_opts[:host_key]   = vars(:ssh_host_key).split(/,\s*/) if vars(:ssh_host_key)
      ssh_opts[:hmac]       = vars(:ssh_hmac).split(/,\s*/) if vars(:ssh_hmac)

      if Oxidized.config.input.debug?
        ssh_opts[:logger]  = Oxidized.logger
        ssh_opts[:verbose] = Logger::DEBUG
      end

      ssh_opts
    end
  end
end
