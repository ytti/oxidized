module Oxidized
  class RestClient
    require 'net/http'
    require 'json'
    HOST = 'localhost'
    PORT = 8888

    class << self
      def next opt={}, host=HOST, port=PORT
        web = new host, port
        web.next opt
      end
    end

    def initialize host=HOST, port=PORT
      @web = Net::HTTP.new host, port
    end

    def next opt
      data = JSON.dump opt
      @web.put '/node/next/' + opt[:name].to_s, data
    end

  end
end
