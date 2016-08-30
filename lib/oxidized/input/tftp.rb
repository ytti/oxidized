module Oxidized
  require 'timeout'
  require 'stringio'
  require_relative 'cli'

  class TFTP < Input
    RescueFail = {
      :debug => [
        #Net::SSH::Disconnect,
      ],
      :warn => [
        #RuntimeError,
        #Net::SSH::AuthenticationFailed,
      ],
    }
    
    include Input::CLI
    
    # TFTP utilizes UDP, there is not a connection. We simply specify an IP and send/receive data.
    def connect node
      begin
        require 'net/tftp'
      rescue LoadError
        raise OxidizedError, 'net/tftp not found: sudo gem install net-tftp'
      end
      @node       = node

      @node.model.cfg['tftp'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-tftp", 'w') if Oxidized.config.input.debug?
      @tftp = Net::TFTP.new @node.ip
    end

    def cmd file
      Oxidized.logger.info file.methods(true)
      Oxidized.logger.debug "TFTP: #{file} @ #{@node.name}"
      config = StringIO.new
      @tftp.getbinary file, config
      config.rewind
      config.read
    end
    

    # meh not sure if this is the best way, but perhaps better than not implementing send
    def send my_proc
      my_proc.call
    end

    def output
      ""
    end

    private

    def disconnect
      # TFTP uses UDP, there is no connection to close
    #rescue Errno::ECONNRESET, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
    end

  end
end
