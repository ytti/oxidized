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
      data = JSON.parse(read_http(node_want))
      data = string_navigate(data, @cfg.hosts_location) if @cfg.hosts_location?
      data.each do |node|
        next if node.empty?

        # map node parameters
        keys = {}
        @cfg.map.each do |key, want_position|
          keys[key.to_sym] = node_var_interpolate string_navigate(node, want_position)
        end
        keys[:model] = map_model keys[:model] if keys.has_key? :model

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

    def read_http(node_want)
      uri = URI.parse(@cfg.url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @cfg.secure

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
