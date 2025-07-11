module Oxidized
  require "oxidized/input/cli"
  require "net/http"
  require "json"
  require "net/http/digest_auth"

  class HTTP < Input
    include Input::CLI

    def connect(node)
      @node = node
      @secure = false
      @username = nil
      @password = nil
      @headers = {}
      @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-http", "w") if Oxidized.config.input.debug?
      @node.model.cfg["http"].each { |cb| instance_exec(&cb) }

      return true unless @main_page && defined?(login)

      begin
        require "mechanize"
      rescue LoadError
        raise OxidizedError, "mechanize not found: sudo gem install mechanize"
      end

      @m = Mechanize.new
      url = URI::HTTP.build host: @node.ip, path: @main_page
      @m_page = @m.get(url.to_s)
      login
    end

    def cmd(callback_or_string)
      return cmd_cb callback_or_string if callback_or_string.is_a?(Proc)

      cmd_str callback_or_string
    end

    def cmd_cb(callback)
      instance_exec(&callback)
    end

    def cmd_str(string)
      path = string % { password: @node.auth[:password] }
      get_http path
    end

    private

    def get_http(path)
      schema = @secure ? "https://" : "http://"
      uri = URI("#{schema}#{@node.ip}#{path}")

      logger.debug "Making request to: #{uri}"

      ssl_verify = Oxidized.config.input.http.ssl_verify? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

      res = make_request(uri, ssl_verify)

      if res.code == '401' && res['www-authenticate']&.include?('Digest')
        uri.user = @username
        uri.password = URI.encode_www_form_component(@password)
        logger.debug "Server requires Digest authentication"
        auth = Net::HTTP::DigestAuth.new.auth_header(uri, res['www-authenticate'], 'GET')

        res = make_request(uri, ssl_verify, 'Authorization' => auth)
      elsif @username && @password
        logger.debug "Falling back to Basic authentication"
        res = make_request(uri, ssl_verify, 'Authorization' => basic_auth_header)
      end

      logger.debug "Response code: #{res.code}"
      res.body
    end

    def make_request(uri, ssl_verify, extra_headers = {})
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", verify_mode: ssl_verify) do |http|
        req = Net::HTTP::Get.new(uri)
        @headers.merge(extra_headers).each { |header, value| req.add_field(header, value) }
        logger.debug "Sending request with headers: #{@headers.merge(extra_headers)}"
        http.request(req)
      end
    end

    def basic_auth_header
      "Basic " + ["#{@username}:#{@password}"].pack('m').delete("\r\n")
    end

    def log(str)
      @log&.write(str)
    end

    def disconnect
      @log.close if Oxidized.config.input.debug?
    end
  end
end
