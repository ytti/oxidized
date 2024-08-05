module Oxidized
  require "oxidized/source/jsonfile"
  class HTTP < JSONFile
    def initialize
      super
      @cfg = Oxidized.config.source.http
    end

    def setup
      Oxidized.setup_logger
      return unless @cfg.url.empty?

      raise NoConfig, 'no source http url config, edit ~/.config/oxidized/config'
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
