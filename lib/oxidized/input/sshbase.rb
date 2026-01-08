module Oxidized
  require 'net/ssh'
  require 'timeout'

  class SSHBase < Input
    RESCUE_FAIL = {
      Net::SSH::Disconnect           => :debug,
      Net::SSH::ConnectionTimeout    => :debug,
      Net::SSH::AuthenticationFailed => :warn,
      Net::SSH::HostKeyUnknown       => :warn
    }.freeze

    def self.rescue_fail
      super.merge(RESCUE_FAIL)
    end

    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node = node
      @node.model.cfg[config_name].each { |cb| instance_exec(&cb) }
      setup_debug_logging
      logger.debug "Connecting to #{@node.name}"
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      connected?
    end

    def connected?
      @ssh && (not @ssh.closed?)
    end

    def setup_debug_logging
      return unless Oxidized.config.input.debug?

      logfile = Oxidized::Config::LOG + "/#{@node.ip}-#{config_name}"
      @log = File.open(logfile, 'w')
      logger.debug "I/O Debugging to #{logfile}"
    end

    def make_ssh_opts
      ssh_opts = {
        number_of_password_prompts:      0,
        keepalive:                       vars(:ssh_no_keepalive) ? false : true,
        verify_host_key:                 must_secure? ? :always : :never,
        append_all_supported_algorithms: true,
        password:                        @node.auth[:password],
        timeout:                         @node.timeout,
        port:                            (vars(:ssh_port) || 22).to_i,
        forward_agent:                   false
      }

      auth_methods = vars(:auth_methods) || %w[none publickey password]
      ssh_opts[:auth_methods] = auth_methods
      logger.debug "AUTH METHODS::#{auth_methods}"

      if vars(:ssh_proxy)
        ssh_opts[:proxy] = make_ssh_proxy_command(
          vars(:ssh_proxy), vars(:ssh_proxy_port), must_secure?
        )
      end
      ssh_opts[:keys]       = [vars(:ssh_keys)].flatten           if vars(:ssh_keys)
      ssh_opts[:kex]        = vars(:ssh_kex).split(/,\s*/)        if vars(:ssh_kex)
      ssh_opts[:encryption] = vars(:ssh_encryption).split(/,\s*/) if vars(:ssh_encryption)
      ssh_opts[:host_key]   = vars(:ssh_host_key).split(/,\s*/)   if vars(:ssh_host_key)
      ssh_opts[:hmac]       = vars(:ssh_hmac).split(/,\s*/)       if vars(:ssh_hmac)

      # Use our logger for Net::SSH
      ssh_logger = SemanticLogger[Net::SSH]
      ssh_logger.level = Oxidized.config.input.debug? ? :debug : :fatal
      ssh_opts[:logger] = ssh_logger

      ssh_opts
    end

    def must_secure?
      Oxidized.config.input[config_name].secure? == true
    end

    def make_ssh_proxy_command(proxy_host, proxy_port, secure)
      return nil unless !proxy_host.nil? && !proxy_host.empty?

      proxy_command =  "ssh "
      proxy_command += "-o StrictHostKeyChecking=no " unless secure
      proxy_command += "-p #{proxy_port} "            if proxy_port
      proxy_command += "#{proxy_host} -W [%h]:%p"
      Net::SSH::Proxy::Command.new(proxy_command)
    end

    def disconnect
      Timeout.timeout(@node.timeout) do
        @ssh.close
      end
    rescue Timeout::Error
      logger.debug "#{@node.name} timed out while disconnecting"
    ensure
      @log.close if Oxidized.config.input.debug?
    end

    def config_name
      self.class.name.split('::').last.downcase
    end

    # Methods to implement in subclasses
    def cmd(**_args)
      raise NotImplementedError, "Subclasses must implement cmd"
    end
  end
end
