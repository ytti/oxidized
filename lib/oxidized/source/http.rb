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

    # map headers
    headers = {}
    @cfg.headers.each do |header, value|
      headers[header] = value
    end

    request = Net::HTTP::Get.new(uri.request_uri, headers)

    response = http.request(request)
    data = JSON.parse(response.body)
    data.each do |line|
      next if line.empty?
      # map node parameters
      keys = {}
      @cfg.map.each do |key, position|
        keys[key.to_sym] = line[position]
      end
      keys[:model] = map_model keys[:model] if keys.key? :model

      # map node specific vars, empty value is considered as nil
      vars = {}
      @cfg.vars_map.each { |key, position| vars[key.to_sym] = line[position].to_s.empty? ? nil : line[position] }
      keys[:vars] = vars unless vars.empty?

      nodes << keys
    end
    nodes
  end

end
end
