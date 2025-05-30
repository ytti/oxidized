module Oxidized
  class RestClient
    require 'net/http'
    require 'json'
    require 'uri'
    require 'asetus'

    class Config
      ROOT = ENV['OXIDIZED_HOME'] || File.join(Dir.home, '.config', 'oxidized')
    end

    CFGS = Asetus.new name: 'oxidized', load: false, key_to_s: true
    CFGS.default.rest = '127.0.0.1:8888'

    begin
      CFGS.load
    rescue StandardError => e
      raise InvalidConfig, "Error loading config: #{e.message}"
    end

    restcfg = CFGS.cfg.rest
    restcfg.insert(0, 'http://') unless restcfg =~ /^http:\/\//

    HOST = URI(restcfg).host
    PORT = URI(restcfg).port
    PATH = URI(restcfg).path

    class << self
      def next(opt = {}, host = HOST, port = PORT)
        web = new host, port
        web.next opt
      end
    end

    def initialize(host = HOST, port = PORT)
      @web = Net::HTTP.new host, port
    end

    def next(opt)
      data = JSON.dump opt
      headers = { 'content-type': 'application/json' }
      @web.put PATH + '/node/next/' + opt[:name].to_s, data, headers
    end
  end
end
