module Oxidized
  require 'net/http'
  require 'net/https'
  begin
    require 'nokogiri'
  rescue LoadError
    raise OxidizedError, 'nokogiri not found: sudo gem install nokogiri'
  end

  class Panos_HTTP < Input

    def connect node  
      @node = node  
      @node.model.cfg['panos_http'].each { |cb| instance_exec(&cb) }  
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-panos-http", 'w') if Oxidized.config.input.debug?  
      @http = Net::HTTP.new(@node.ip, vars(:https_port) || 443)
      @http.use_ssl = true  
      # TODO make this configurable, this is not desirable for every environment
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      apikey_response = apicall(URI.encode_www_form({
        :user => node.auth[:username],
        :password => node.auth[:password],
        :type => 'keygen'
      }))

      status = apikey_response.xpath('//response/@status').first
      if status.to_s != 'success'
        msg = apikey_response.xpath('//response/result/msg').text
        disconnect
        raise OxidizedError, ('Could not generate PanOS API key: ' + msg)
      end
      @apikey = apikey_response.xpath('//response/result/key').text.to_s

      connected?
    end

    def connected?
      @apikey != nil
    end

    def cmd(params)
      apicall("#{params}&key=#{CGI::escape(@apikey)}").to_xml(:indent => 2)
    end

    # I do not understand these two methods, I just copied them from ftp.rb
    def send my_proc
      my_proc.call
    end

    def output
      ""
    end

    def get
      @node.model.get
    end

    private
    def apicall params
      response = @http.request_get('/api?' + params)
      Nokogiri::XML(response.body)
    end

    def disconnect
      @http.finish
      @http = nil
      @apikey = nil
    #rescue Errno::ECONNRESET, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
    end

  end
end
