module Oxidized
  require 'net/http'
  require 'net/https'
  require_relative 'cli'

  class HTTP < Input
    RescueFail = {
      :debug => [
      ],
      :warn => [
      ],
    }

    # Why? This is not a CLI method... but if not, it doesn't get registered
    # in the manager...
    include Input::CLI
    
    def connect node  
      @node = node  
      @mode.model.cfg['http'].each { |cb| instance_exec(&cb) }  
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-http", 'w') if Oxidized.config.input.debug?  
      # Don't use @node.ip here, because this will make Net::HTTP not send a  
      # correct HOST header.  
      @http = Net::HTTP.new(@node.name)  
      if vars(:ssl)  
        @http.use_ssl = true  
        @http.port = vars(:https_port) || 443  
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless Oxidized.config.input.http.validate_ssl_cert  
      else  
        @http.port = vars(:http_port) || 80  
      end  
      connected?
    end
  
    def connected?  
      @http and not @http.finished?  
    end  
  
    def cmd req  
      Oxidized.logger.debug "HTTP: #{req.method} #{req.path} @ #{@node.name}"  
      @http.request req  
    end  

    # I do not understand these two methods, I just copied them from ftp.rb
    def send my_proc
      my_proc.call
    end

    def output
      ""
    end

    private

    def disconnect
      @http.finish
    #rescue Errno::ECONNRESET, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
    end

  end
end
