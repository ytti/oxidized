module Oxidized
  require 'stringio'
  require_relative 'cli'

  begin
    require 'net/tftp'
  rescue LoadError
    raise OxidizedError, 'net/tftp not found: sudo gem install net-tftp'
  end

  class TFTP < Input
    include Input::CLI

    # TFTP utilizes UDP, there is not a connection. We simply specify an IP and send/receive data.
    def connect(node)
      @node = node

      @node.model.cfg['tftp'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-tftp", 'w') if Oxidized.config.input.debug?
      @tftp = Net::TFTP.new @node.ip
    end

    def cmd(file)
      Oxidized.logger.debug "TFTP: #{file} @ #{@node.name}"
      config = StringIO.new
      @tftp.getbinary file, config
      config.rewind
      config.read
    end

    private

    def disconnect
      # TFTP uses UDP, there is no connection to close
      true
    ensure
      @log.close if Oxidized.config.input.debug?
    end
  end
end
