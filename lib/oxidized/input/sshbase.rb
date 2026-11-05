module Oxidized
  require 'net/ssh'
  require 'net/ssh/proxy/command'
  require 'resolv'
  require 'timeout'

  class SSHBase < Input
    RESCUE_FAIL = {
      Net::SSH::Disconnect           => :debug,
      Net::SSH::ConnectionTimeout    => :debug,
      Net::SSH::AuthenticationFailed => :warn,
      Net::SSH::HostKeyUnknown       => :warn
    }.freeze

    PROXY_USER = /\A[A-Za-z0-9._][A-Za-z0-9._-]*\z/
    # RFC 1123
    HOST_LABEL = /[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?/
    # Short hostname or FQDN, without trailing dot
    HOSTNAME   = /\A(?=.{1,253}\z)#{HOST_LABEL}(?:\.#{HOST_LABEL})*\z/

    def self.rescue_fail
      super.merge(RESCUE_FAIL)
    end

    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node = node
      @node.model.cfg[config_name].each { |cb| instance_exec(&cb) }
      logger.debug "Connecting to #{@node.name}"
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], make_ssh_opts)
      connected?
    end

    def connected?
      @ssh && (not @ssh.closed?)
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
        forward_agent:                   false,
        max_win_size:                    2 * 1024 * 1024 # Issue #3867 - Mikrotik ROSSH is broken
      }

      auth_methods = vars(:auth_methods) || %w[none publickey password]
      ssh_opts[:auth_methods] = auth_methods
      logger.debug "AUTH METHODS::#{auth_methods}"

      if vars(:ssh_proxy)
        ssh_opts[:proxy] = make_ssh_proxy_command(
          vars(:ssh_proxy), vars(:ssh_proxy_port), must_secure?
        )
      end
      ssh_opts[:keys]              = [vars(:ssh_keys)].flatten                  if vars(:ssh_keys)
      ssh_opts[:kex]               = vars(:ssh_kex).split(/,\s*/)               if vars(:ssh_kex)
      ssh_opts[:encryption]        = vars(:ssh_encryption).split(/,\s*/)        if vars(:ssh_encryption)
      ssh_opts[:host_key]          = vars(:ssh_host_key).split(/,\s*/)          if vars(:ssh_host_key)
      ssh_opts[:hmac]              = vars(:ssh_hmac).split(/,\s*/)              if vars(:ssh_hmac)
      ssh_opts[:pubkey_algorithms] = vars(:ssh_pubkey_algorithms).split(/,\s*/) if vars(:ssh_pubkey_algorithms)
      ssh_opts[:minimum_dh_bits]   = Integer(vars(:ssh_minimum_dh_bits).to_s, 10) if vars(:ssh_minimum_dh_bits)

      # Use our logger for Net::SSH
      ssh_logger = SemanticLogger[Net::SSH]
      config_debug = Oxidized.config.input.debug
      if config_debug == true ||
         (config_debug.is_a?(String) && config_debug.downcase.include?('library'))
        ssh_logger.level = :debug
      else
        ssh_logger.level = :fatal
      end
      ssh_opts[:logger] = ssh_logger

      ssh_opts
    end

    def must_secure?
      Oxidized.config.input[config_name].secure? == true
    end

    def make_ssh_proxy_command(proxy_host, proxy_port, secure)
      return nil unless !proxy_host.nil? && !proxy_host.empty?
      raise ArgumentError, "invalid ssh_proxy: #{proxy_host.inspect}" unless valid_proxy_host?(proxy_host)

      proxy_command =  "ssh "
      proxy_command += "-o StrictHostKeyChecking=no " unless secure
      proxy_command += "-p #{Integer(proxy_port.to_s, 10)} " if proxy_port
      # net-ssh substitutes %h, %p... in the command, % may be in an IPv6 zone ID
      proxy_command += "#{proxy_host.gsub('%', '%%')} -W [%h]:%p"
      Net::SSH::Proxy::Command.new(proxy_command)
    end

    # [user@]host, where host is a hostname, an IPv4 or an IPv6 address
    def valid_proxy_host?(proxy_host)
      user, separator, host = proxy_host.rpartition('@')
      return false unless separator.empty? || user.match?(PROXY_USER)

      host.match?(HOSTNAME) ||
        host.match?(Resolv::IPv4::Regex) ||
        host.match?(Resolv::IPv6::Regex)
    end

    def disconnect
      disconnect_cli
      Timeout.timeout(@node.timeout) do
        @ssh.close
      end
    rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError => e
      logger.debug 'The other side closed the connection while ' \
                   "disconnecting, raising #{e.class} with #{e.message}"
    rescue Timeout::Error
      logger.debug "#{@node.name} timed out while disconnecting"
    end

    # Methods to implement in subclasses
    def cmd(**_args)
      raise NotImplementedError, "Subclasses must implement cmd"
    end
  end
end
