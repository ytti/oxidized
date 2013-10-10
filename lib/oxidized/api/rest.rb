module Oxidized
  require 'webrick'
  require 'json'
  module API
    class Rest
      module Helpers
        def send res, msg='OK', status=200
          msg = {:result => msg}
          res['Content-Type'] = 'application/json'
          res.status = status
          res.body = JSON.dump msg
        end
      end
      include Oxidized::API::Rest::Helpers
      def initialize nodes, listen
        @nodes = nodes
        addr, port = listen.to_s.split ':'
        port, addr = addr, nil if not port
        @web = WEBrick::HTTPServer.new :BindAddress=>addr, :Port=>port, :Logger=>Log, :AccessLog=>[]
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
        @web.mount '/nodes/next', Next, @nodes
        @web.mount_proc '/nodes' do |req, res|
          #script_name, #path_info
          case req.path_info[1..-1]
          # /nodes/reload - reloads list of nodes
          when 'reload'
            @nodes.load
            send res
          # /nodes/list - returns list of nodes
          when 'list'
            send res, @nodes.list
          # /nodes/show/node - returns data about node
          when /show\/(.*)/
            send res, @nodes.show($1)
          when /fetch\/(.*)/ # primitive node fetch implementation for file config - /nodes/fetch/$ip_address
            if CFG.output[:default] == "file" and $1 != '' # ugly hack to disable configuration fetch for non ascii configurations and ensure that argument is received
              @cfg_root = CFG.output[:file]
              File.open("#{@cfg_root[:directory]}/#{$1}", "r") do |pipe|
                @res_config = []
                while ( line = pipe.gets ) do
                  @res_config << line # store configuration into an array to format and send
                end
              end
              send res, @res_config
            elsif CFG.output[:default] != "file" and $1 != '' 
              send res, "oxidized 0.0.14 support fetch for ascii configuration files only." # return error to end user 
            else # return error if no argument is received
              send res, "missing argument - example: /nodes/fetch/192.0.2.1"
            end
          end
        end
      end

      # /nodes/next/node - moves node to head of queue
      class Next < WEBrick::HTTPServlet::AbstractServlet
        include Oxidized::API::Rest::Helpers
        def initialize server, nodes
          super server
          @nodes = nodes
        end
        def do_GET req, res
          @nodes.next req.path_info[1..-1]
          send res
        end
        def do_PUT req, res
          node = req.path_info[1..-1]
          begin
            opt = JSON.load req.body
            Log.debug "before: #{@nodes.list}"
            @nodes.next node, opt
            Log.debug "after: #{@nodes.list}"
            send res
          rescue JSON::ParserError
            send res, 'broken JSON', 400
          end
        end
      end

    end
  end
end
