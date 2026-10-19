module Oxidized
  require 'net/ssh'
  begin
    require 'net/scp'
  rescue LoadError
    raise OxidizedError, 'net/scp not found: sudo gem install net-scp'
  end
  require 'timeout'
  require_relative 'sshbase'

  class SCP < SSHBase
    RESCUE_FAIL = {
      Net::SCP::Error => :warn,
      # net-scp raises ArgumentError on error replies missing the \2 prefix, see #3900
      ArgumentError   => :warn
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
