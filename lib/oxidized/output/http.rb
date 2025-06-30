module Oxidized
  module Output
    class Http < Output
      attr_reader :commitref

      def initialize
        super
        @cfg = Oxidized.config.output.http
      end

      def setup
        return unless @cfg.empty?

        Oxidized.asetus.user.output.http.user = 'Oxidized'
        Oxidized.asetus.user.output.http.pasword = 'secret'
        Oxidized.asetus.user.output.http.url = 'http://localhost/web-api/oxidized'
        Oxidized.asetus.save :user
        raise NoConfig, "no output http config, edit #{Oxidized::Config.configfile}"
      end

      require "net/http"
      require "uri"
      require "json"

      def store(node, outputs, opt = {})
        @commitref = nil
        uri = URI.parse @cfg.url
        http = Net::HTTP.new uri.host, uri.port
        # http.use_ssl = true if uri.scheme = 'https'
        req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
        req.basic_auth @cfg.user, @cfg.password
        req.body = generate_json(node, outputs, opt)
        response = http.request req

        case response.code.to_i
        when 200 || 201
          logger.info "Configuration http backup complete for #{node}"
          p [:success]
        when (400..499)
          logger.info "Configuration http backup for #{node} failed status: #{response.body}"
          p [:bad_request]
        when (500..599)
          p [:server_problems]
          logger.info "Configuration http backup for #{node} failed status: #{response.body}"
        end
      end

      private

      def generate_json(node, outputs, opt)
        JSON.pretty_generate(
          'msg'    => opt[:msg],
          'user'   => opt[:user],
          'email'  => opt[:email],
          'group'  => opt[:group],
          'node'   => node,
          'config' => outputs.to_cfg
          # actually we need to also iterate outputs, for other types like in gitlab.
          # But most people don't use 'type' functionality.
        )
      end
    end
  end
end
