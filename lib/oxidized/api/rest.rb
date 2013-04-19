module Oxidized
  require 'webrick'
  require 'json'
  module API
    class Rest
      def initialize nodes, listen
        @nodes = nodes
        addr, port = listen.to_s.split ':'
        port, addr = addr, nil if not port
        @web = WEBrick::HTTPServer.new :BindAddress=>addr, :Port=>port
        maps
      end
      def work
        req = select @web.listeners, nil, nil, Config::Sleep
        while req
          @web.run req.first.first.accept
          req = select @web.listeners, nil, nil, 0
        end
      end
      def maps
        @web.mount_proc '/nodes' do |req, res|
          #script_name, #path_info
          case req.path_info[1..-1]
          # /nodes/reload - reloads list of nodes
          when 'reload'
            @nodes.load
            res.body = JSON.dump 'OK'
          # /nodes/next/node - moves node to head of queue
          when /next\/(.*)/
            @nodes.next $1
            res.body = JSON.dump 'OK'
          # /nodes/list - returns list of nodes
          when 'list'
            res.body = JSON.dump @nodes.list
          # /nodes/show/node - returns data about node
          when /show\/(.*)/
            res.body = JSON.dump @nodes.show $1
          end
        end
      end
    end
  end
end
