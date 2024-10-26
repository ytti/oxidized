require 'net/http'
module Oxidized
  module Models
    # Represents the NSXConfig model.
    #
    # Handles configuration retrieval and processing for NSXConfig devices.

    class NSXConfig < Oxidized::Models::Model
      using Refinements

      cmd "/api/4.0/edges/" do |cfg|
        edges = JSON.parse(cfg.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))["edgePage"]["data"]
        data = []
        edges.each do |edge|
          firewall_config = cmd "/api/4.0/edges/#{edge['id']}"
          json_config = JSON.parse(firewall_config.encode('UTF-8', { invalid: :replace, undef: :replace, replace: '?' }))
          json_config["edgeInfo"] = "#{edge['id']} #{edge['name']}"
          data.push(json_config)
        end
        JSON.pretty_generate(data)
      end

      cfg :http do
        @username = @node.auth[:username]
        @password = @node.auth[:password]
        @headers['Content-Type'] = 'application/json'
        @headers['Accept'] = 'application/json'
        @secure = true
      end
    end
  end
end
