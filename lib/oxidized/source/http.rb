module Oxidized
  module Source
    require "oxidized/source/jsonfile"
    class HTTP < JSONFile
      def initialize
        super
        @cfg = Oxidized.config.source.http
      end

      def setup
        Oxidized.setup_logger
        if @cfg.empty?
          Oxidized.asetus.user.source.http.url       = 'https://url/api'
          Oxidized.asetus.user.source.http.map.name  = 'name'
          Oxidized.asetus.user.source.http.map.model = 'model'
          Oxidized.asetus.save :user

          raise NoConfig, "No source http config, edit #{Oxidized::Config.configfile}"
        end

        # check for mandatory attributes
        if !@cfg.has_key?('url')
          raise InvalidConfig, "url is a mandatory http source attribute, edit #{Oxidized::Config.configfile}"
        elsif !@cfg.map.has_key?('name')
          raise InvalidConfig, "map/name is a mandatory source attribute, edit #{Oxidized::Config.configfile}"
        end
      end

      require "net/http"
      require "net/https"
      require "uri"
      require "json"

      def load(node_want = nil)
        uri = URI.parse(@cfg.url)
        data = JSON.parse(read_http(uri, node_want))
        node_data = data
        node_data = string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?
        node_data = pagination(data, node_want) if @cfg.pagination?

        transform_json(node_data)
      end

      private

      def pagination(data, node_want)
        node_data = []
        raise Oxidized::OxidizedError, "if using pagination, 'pagination_key_name' setting must be set" unless @cfg.pagination_key_name?

        next_key = @cfg.pagination_key_name
        loop do
          node_data += string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?
          break if data[next_key].nil?

          new_uri = URI.parse(data[next_key]) if data.has_key?(next_key)
          data = JSON.parse(read_http(new_uri, node_want))
          node_data += string_navigate_object(data, @cfg.hosts_location) if @cfg.hosts_location?
        end
        node_data
      end

      def read_http(uri, node_want)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @cfg.secure

        # Add read_timeout to handle case of big list of nodes (default value is 60 seconds)
        http.read_timeout = Integer(@cfg.read_timeout) if @cfg.has_key? "read_timeout"

        # map headers
        headers = {}
        @cfg.headers.each do |header, value|
          headers[header] = value
        end

        req_uri = uri.request_uri
        req_uri = "#{req_uri}/#{node_want}" if node_want
        request = Net::HTTP::Get.new(req_uri, headers)
        request.basic_auth(@cfg.user, @cfg.pass) if @cfg.user? && @cfg.pass?
        http.request(request).body
      end
    end
  end
end
