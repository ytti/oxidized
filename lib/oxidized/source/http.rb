module Oxidized
  class HTTP < Source
    def initialize
      @cfg = Oxidized.config.source.http
      super
    end

    def setup
      return unless @cfg.url.empty?

      raise NoConfig, 'no source http url config, edit ~/.config/oxidized/config'
    end

    require "net/http"
    require "net/https"
    require "uri"
    require "json"

    def load(node_want = nil)
      nodes = []
      data = read_http(node_want)
      data.each do |node|
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

    def set_request(l_uri, l_headers, l_node_want)
      req_uri = l_uri.request_uri
      req_uri = "#{req_uri}/#{l_node_want}" if l_node_want
      request = Net::HTTP::Get.new(req_uri, l_headers)
      request.basic_auth(@cfg.user, @cfg.pass) if @cfg.user? && @cfg.pass?
      request
    end

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

    def check_pagination(response, http, headers, node_want)
      node_data = []
      if @cfg.pagination?
        raise Oxidized::OxidizedError, "if using pagination, 'pagination_key_name' setting must be set" unless @cfg.pagination_key_name?

        if @cfg.pagination_key_name?
          next_key = @cfg.pagination_key_name
          loop do
            data = JSON.parse(response.body)
            node_data += string_navigate(data, @cfg.hosts_location) if @cfg.hosts_location?
            break if data[next_key].nil?

            new_uri = URI.parse(data[next_key]) if data.has_key?(next_key)
            request = set_request(new_uri, headers, node_want)
            response = http.request(request)
          end
        end
      # since new feature; dont break curent configs
      else
        data = JSON.parse(response.body)
        node_data += string_navigate(data, @cfg.hosts_location) if @cfg.hosts_location?
      end
      node_data
    end

    def read_http(node_want)
      uri = URI.parse(@cfg.url)
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

      request = set_request(uri, headers, node_want)
      response = http.request(request)

      check_pagination(response, http, headers, node_want)
    end
  end
end
