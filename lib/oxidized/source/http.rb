module Oxidized
class HTTP < Source
  def initialize
    @cfg = Oxidized.config.source.http
    super
  end

  def setup
    if @cfg.url.empty?
      raise NoConfig, 'no source http url config, edit ~/.config/oxidized/config'
    end
  end

  require "net/http"
  require "uri"
  require "json"

  def load
    nodes = []
    uri = URI.parse(@cfg.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @cfg.secure

    # map headers
    headers = {}
    @cfg.headers.each do |header, value|
      headers[header] = value
    end

    request = Net::HTTP::Get.new(uri.request_uri, headers)
    if (@cfg.user? && @cfg.pass?)
        request.basic_auth(@cfg.user,@cfg.pass)
    end

    response = http.request(request)
    data = JSON.parse(response.body)
    data.each do |node|
      next if node.empty?
      # map node parameters
      keys = {}
      @cfg.map.each do |key, want_position|
        want_positions = want_position.split('.')
        keys[key.to_sym] = node_var_interpolate node.dig(*want_positions)
      end
      keys[:model] = map_model keys[:model] if keys.key? :model

      # map node specific vars
      vars = {}
      @cfg.vars_map.each do |key, want_position|
        want_positions = want_position.split('.')
        vars[key.to_sym] = node_var_interpolate node.dig(*want_positions)
      end
      keys[:vars] = vars unless vars.empty?

      nodes << keys
    end
    nodes
  end

end
end

if RUBY_VERSION < '2.3'
  class Hash
    def dig(key, *rest)
      value = self[key]
      if value.nil? || rest.empty?
        value
      elsif value.respond_to?(:dig)
        value.dig(*rest)
      else # foo.bar.baz (bar exist but is not hash)
        return nil
      end
    end
  end
end
