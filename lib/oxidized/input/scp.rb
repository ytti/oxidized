module Oxidized
  require 'net/ssh'
  require 'net/scp'
  require 'timeout'
  require_relative 'cli'

  class SCP < Input
    RESCUE_FAIL = {
      debug: [
        # Net::SSH::Disconnect,
      ],
      warn:  [
        # RuntimeError,
        # Net::SSH::AuthenticationFailed,
      ]
    }.freeze
    include Input::CLI

    def connect(node) # rubocop:disable Naming/PredicateMethod
      @node = node
      @node.model.cfg['scp'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-scp", 'w') if Oxidized.config.input.debug?
      @ssh = Net::SSH.start(@node.ip, @node.auth[:username], password: @node.auth[:password])
      connected?
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
