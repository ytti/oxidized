module Oxidized
  require 'net/ssh'
  require 'net/scp'
  require 'timeout'
  require_relative 'cli'

  class SCP < Input
    RESCUE_FAIL = {
      warn: [
        Net::SCP::Error,
        Net::SSH::HostKeyUnknown,
        Net::SSH::AuthenticationFailed
      ]
    }.freeze
    include Input::CLI

    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node = node
      @node.model.cfg['scp'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-scp", 'w') if Oxidized.config.input.debug?
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      connected?
    end

    def make_ssh_opts
      secure = Oxidized.config.input.scp.secure?
      ssh_opts = {
        number_of_password_prompts:      0,
        verify_host_key:                 secure ? :always : :never,
        append_all_supported_algorithms: true,
        password:                        @node.auth[:password],
        timeout:                         Oxidized.config.timeout,
        port:                            (vars(:ssh_port) || 22).to_i,
        forward_agent:                   false
      }

      # Use our logger for Net::SSH
      ssh_logger = SemanticLogger[Net::SSH]
      ssh_logger.level = Oxidized.config.input.debug? ? :debug : :fatal
      ssh_opts[:logger] = ssh_logger

      ssh_opts
    end

    def connected?
      @ssh && (not @ssh.closed?)
    end

    def cmd(file)
      logger.debug "SCP: #{file} @ #{@node.name}"
      @ssh.scp.download!(file)
    end

    def send(my_proc)
      my_proc.call
    end

    def output
      ""
    end

    private

    def disconnect
      @ssh.close
    ensure
      @log.close if Oxidized.config.input.debug?
    end
  end
end
