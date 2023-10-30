module Oxidized
  class HTTP < Source
    def initialize
      @cfg = Oxidized.config.source.http
      super
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
      nodes = []
      node_data = []
      uri = URI.parse(@cfg.url)
      data = JSON.parse(read_http(uri, node_want))
      node_data = data
      node_data = string_navigate(data, @cfg.hosts_location) if @cfg.hosts_location?
      if @cfg.pagination?
        node_data = pagination(data, node_want)
      end

      # at this point we have all the nodes; pagination or not
      node_data.each do |node|
        next if node.empty?

        # map node parameters
        keys = {}
        @cfg.map.each do |key, want_position|
          keys[key.to_sym] = node_var_interpolate string_navigate(node, want_position)
        end
        keys[:model] = map_model keys[:model] if keys.has_key? :model
        keys[:group] = map_group keys[:group] if keys.has_key? :group

        # map node specific vars
        vars = {}
        @cfg.vars_map.each do |key, want_position|
          vars[key.to_sym] = node_var_interpolate string_navigate(node, want_position)
        end
        keys[:vars] = vars unless vars.empty?

        nodes << keys
      end
      nodes
    end

    private

    def string_navigate(object, wants)
      wants = wants.split(".").map do |want|
        head, match, _tail = want.partition(/\[\d+\]/)
        match.empty? ? head : [head, match[1..-2].to_i]
      end
      wants.flatten.each do |want|
        object = object[want] if object.respond_to? :each
      end
      object
    end

    def pagination(data, node_want)
      node_data = []
      raise Oxidized::OxidizedError, "if using pagination, 'pagination_key_name' setting must be set" unless @cfg.pagination_key_name?

      next_key = @cfg.pagination_key_name
      loop do
	node_data += string_navigate(data, @cfg.hosts_location) if @cfg.hosts_location?
        break if data[next_key].nil?
        
	new_uri = URI.parse(data[next_key]) if data.has_key?(next_key)
        data = JSON.parse(read_http(new_uri, node_want))
	node_data += string_navigate(data, @cfg.hosts_location) if @cfg.hosts_location?
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
