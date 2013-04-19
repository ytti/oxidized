# this is not used, just added here if I want to revive it

module Oxidized
  require 'socket'
  require 'json'
  module API
    class Domain
      def initialize nodes, socket=CFG.api
        puts 'here'
        @nodes = nodes
        File.unlink socket rescue Errno::ENOENT
        @server = UNIXServer.new socket
      end
      def work
        io = select [@server], nil, nil, Config::Sleep
        process io.first.first.accept if io
      end
      def read
        @socket.recv 1024
      end
      def write data=''
        begin
          @socket.send JSON.dump(data), 0
        rescue Errno::EPIPE
        end
      end
      def process socket
        @socket = socket
        cmd = read
        cmd, data = cmd.split /\s+/, 2
        data = data.to_s.chomp
        case cmd
        when /next/i
          @nodes.next data
          write 'OK'
        when /reload/i
          @nodes.load if data.match /nodes/i
          write 'OK'
        when /list/i
          write @nodes.map{|e|e.name}
        when /node/i
          write @nodes.show(data)
        end
        @socket.close
      end
    end
  end
end
