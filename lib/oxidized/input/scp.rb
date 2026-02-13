module Oxidized
  require 'net/ssh'
  require 'net/scp'
  require 'timeout'
  require_relative 'sshbase'

  class SCP < SSHBase
    RESCUE_FAIL = {
      Net::SCP::Error => :warn
    }.freeze

    def self.rescue_fail
      super.merge(RESCUE_FAIL)
    end

    def cmd(file)
      logger.debug "SCP: #{file} @ #{@node.name}"
      Timeout.timeout(@node.timeout) do
        @ssh.scp.download!(file)
      end
    end
  end
end
