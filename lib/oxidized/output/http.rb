module Oxidized
  module Output
    # HTTP output class for sending configuration backups to a web API.
    class Http < Output
      # @!attribute [rw] commitref
      # @return [String] The reference for the last commit or action performed.
      attr_reader :commitref

      # Initializes the HTTP output.
      # Loads the HTTP configuration from Oxidized.
      def initialize
        super
        @cfg = Oxidized.config.output.http
      end

      # Sets up the HTTP configuration. If the configuration is missing, default values are provided.
      #
      # @raise [NoConfig] If there is no HTTP configuration available.
      def setup
        return unless @cfg.empty?

        CFGS.user.output.http.user = 'Oxidized'
        CFGS.user.output.http.pasword = 'secret'
        CFGS.user.output.http.url = 'http://localhost/web-api/oxidized'
        CFGS.save :user
        raise NoConfig, 'no output http config, edit ~/.config/oxidized/config'
      end

      require "net/http"
      require "uri"
      require "json"

      # Stores the configuration for the node by sending it as a POST request to the HTTP API.
      #
      # @param node [String] The node name.
      # @param outputs [Object] The configuration outputs.
      # @param opt [Hash] Additional options for storing, such as user and commit message.
      # @option opt [String] :msg The commit message.
      # @option opt [String] :user The user performing the operation.
      # @option opt [String] :email The email of the user.
      # @option opt [String] :group The group the node belongs to.
      #
      # @return [void]
      def store(node, outputs, opt = {})
        @commitref = nil
        uri = URI.parse @cfg.url
        http = Net::HTTP.new uri.host, uri.port
        # @!visibility private
        # http.use_ssl = true if uri.scheme = 'https'
        req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
        req.basic_auth @cfg.user, @cfg.password
        req.body = generate_json(node, outputs, opt)
        response = http.request req

        case response.code.to_i
        when 200 || 201
          Oxidized.logger.info "Configuration http backup complete for #{node}"
          p [:success]
        when (400..499)
          Oxidized.logger.info "Configuration http backup for #{node} failed status: #{response.body}"
          p [:bad_request]
        when (500..599)
          p [:server_problems]
          Oxidized.logger.info "Configuration http backup for #{node} failed status: #{response.body}"
        end
      end

      private

      # Generates the JSON data to be sent to the HTTP API.
      #
      # @param node [String] The node name.
      # @param outputs [Object] The configuration outputs.
      # @param opt [Hash] Additional options for generating the JSON.
      # @option opt [String] :msg The commit message.
      # @option opt [String] :user The user performing the operation.
      # @option opt [String] :email The email of the user.
      # @option opt [String] :group The group the node belongs to.
      #
      # @return [String] A formatted JSON string of the configuration data.
      def generate_json(node, outputs, opt)
        JSON.pretty_generate(
          'msg'    => opt[:msg],
          'user'   => opt[:user],
          'email'  => opt[:email],
          'group'  => opt[:group],
          'node'   => node,
          'config' => outputs.to_cfg
          # @!visibility private
          # actually we need to also iterate outputs, for other types like in gitlab. But most people don't use 'type' functionality.
        )
      end
    end
  end
end
