module Oxidized
  module Input
    require "oxidized/input/cli"
    require "net/http"
    require "json"
    require "net/http/digest_auth"

    # Manages HTTP connections to retrieve configuration data from network devices.
    #
    # This class extends the Input module and provides methods to connect, send
    # commands, and handle authentication for HTTP requests.
    class HTTP < Input
      include Input::CLI

      # Establishes a connection to the specified node using HTTP.
      #
      # @param node [Node] The node to connect to for HTTP operations.
      # @return [Boolean] True if connection is successful, otherwise raises an error.
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

      # Sends a command to the HTTP server.
      #
      # This method can accept either a string representing a command or a callback.
      #
      # @param callback_or_string [String, Proc] The command string or a callback to execute.
      # @return [String] The response from the HTTP server.
      def cmd(callback_or_string)
        return cmd_cb callback_or_string if callback_or_string.is_a?(Proc)

        cmd_str callback_or_string
      end

      # Executes a command provided as a callback.
      #
      # @param callback [Proc] The callback to execute.
      # @return [void]
      def cmd_cb(callback)
        instance_exec(&callback)
      end

      # Executes a command represented as a string.
      #
      # @param string [String] The command string to execute.
      # @return [String] The response from the HTTP server.
      def cmd_str(string)
        path = string % { password: @node.auth[:password] }
        get_http path
      end

      private

      # Makes an HTTP request to the specified path.
      #
      # @param path [String] The path to request.
      # @return [String] The body of the HTTP response.
      def get_http(path)
        schema = @secure ? "https://" : "http://"
        uri = URI("#{schema}#{@node.ip}#{path}")

        Oxidized.logger.debug "Making request to: #{uri}"

        ssl_verify = Oxidized.config.input.http.ssl_verify? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

        res = make_request(uri, ssl_verify)

        if res.code == '401' && res['www-authenticate']&.include?('Digest')
          uri.user = @username
          uri.password = @password
          Oxidized.logger.debug "Server requires Digest authentication"
          auth = Net::HTTP::DigestAuth.new.auth_header(uri, res['www-authenticate'], 'GET')

          res = make_request(uri, ssl_verify, 'Authorization' => auth)
        elsif @username && @password
          Oxidized.logger.debug "Falling back to Basic authentication"
          res = make_request(uri, ssl_verify, 'Authorization' => basic_auth_header)
        end

        Oxidized.logger.debug "Response code: #{res.code}"
        res.body
      end

      # Makes a low-level HTTP request.
      #
      # @param uri [URI] The URI to request.
      # @param ssl_verify [Integer] The SSL verification mode.
      # @param extra_headers [Hash] Any additional headers to include in the request.
      # @return [Net::HTTPResponse] The HTTP response.
      def make_request(uri, ssl_verify, extra_headers = {})
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", verify_mode: ssl_verify) do |http|
          req = Net::HTTP::Get.new(uri)
          @headers.merge(extra_headers).each { |header, value| req.add_field(header, value) }
          Oxidized.logger.debug "Sending request with headers: #{@headers.merge(extra_headers)}"
          http.request(req)
        end
      end

      # Constructs the Basic Authentication header.
      #
      # @return [String] The Basic Authentication header.
      def basic_auth_header
        "Basic " + ["#{@username}:#{@password}"].pack('m').delete("\r\n")
      end

      # Logs a message to the log file if debugging is enabled.
      #
      # @param str [String] The message to log.
      # @return [void]
      def log(str)
        @log&.write(str)
      end

      # Closes the log file if debugging is enabled.
      #
      # @return [void]
      def disconnect
        @log.close if Oxidized.config.input.debug?
      end
    end
  end
end
