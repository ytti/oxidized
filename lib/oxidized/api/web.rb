module Oxidized
  module API
    class Web
      attr_reader :thread
      def initialize nodes, listen
        require 'oxidized/api/web/webapp'
        addr, port = listen.to_s.split ':'
        port, addr = addr, nil if not port
        WebApp.set :server, %w(puma)
        WebApp.set :bind, addr if addr
        WebApp.set :port, port
        WebApp.set :nodes, nodes
      end
      def run
        @thread = Thread.new { WebApp.run! }
      end
    end
  end
end
