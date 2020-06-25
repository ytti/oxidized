module Oxidized
  require "oxidized/input/cli"
  require "net/http"
  require "json"

  class HTTP < Input
    include Input::CLI

    def connect(node)
      @node = node
      @secure = false
      @username = nil
      @password = nil
      @headers = {}
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-http", "w") if Oxidized.config.input.debug?
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
      req = Net::HTTP::Get.new(uri)
      req.basic_auth @username, @password unless @username.nil?
      @headers.each do |header, value|
        req.add_field(header, value)
      end
      ssl_verify = Oxidized.config.input.http.ssl_verify? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", verify_mode: ssl_verify) do |http|
        http.request(req)
      end
      res.body
    end

    def log(str)
      @log&.write(str)
    end

    def disconnect
      @log.close if Oxidized.config.input.debug?
    end
  end
end
