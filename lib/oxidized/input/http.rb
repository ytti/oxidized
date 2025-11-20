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
      res = perform_http_request(path, method: :get)
      res.body
    end

    def post_http(path, body = nil, extra_headers = {})
      res = perform_http_request(path, method: :post, body: body, extra_headers: extra_headers)
      res.body
    end

    def perform_http_request(path, method: :get, body: nil, extra_headers: {})
      uri = get_uri(path)

      logger.debug "Making #{method.to_s.upcase} request to: #{uri}"

      ssl_verify = Oxidized.config.input.http.ssl_verify? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

      res = make_request(uri, ssl_verify, extra_headers, method: method, body: body)

      if res.code == '401' && res['www-authenticate']&.include?('Digest')
        uri.user = @username
        uri.password = URI.encode_www_form_component(@password)
        logger.debug "Server requires Digest authentication"

        http_method = method.to_s.upcase
        auth = Net::HTTP::DigestAuth.new.auth_header(uri, res['www-authenticate'], http_method)
        res = make_request(uri, ssl_verify, extra_headers.merge('Authorization' => auth),
                           method: method, body: body)

      elsif @username && @password && !authorization_header_present?(extra_headers)
        logger.debug "Falling back to Basic authentication"
        res = make_request(uri, ssl_verify, extra_headers.merge('Authorization' => basic_auth_header),
                           method: method, body: body)
      end

      logger.debug "Response code: #{res.code}"
      res
    end

    def make_request(uri, ssl_verify, extra_headers = {}, method: :get, body: nil)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", verify_mode: ssl_verify) do |http|
        req_class = case method.to_s.downcase.to_sym
                    when :post then Net::HTTP::Post
                    else Net::HTTP::Get
                    end
        req = req_class.new(uri)
        @headers.merge(extra_headers).each { |header, value| req.add_field(header, value) }
        req.body = body if body

        logger.debug "Sending #{method.to_s.upcase} request with headers: #{@headers.merge(extra_headers)}"
        http.request(req)
      end
    end

    def authorization_header_present?(headers)
      headers.keys.any? { |key| key.to_s.downcase == 'authorization' }
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

    def get_uri(path)
      path = URI.parse(path)
      uri_class = @secure ? URI::HTTPS : URI::HTTP
      uri_class.build(host:  @node.ip,
                      path:  path.path,
                      query: path.query)
    end
  end
end
