module Oxidized
  class Input
    module CLI

      def initialize
        @post_login = []
        @pre_logout = []
        @username, @password, @exec = nil
      end

      def get
        connect_cli
        d = @node.model.get
        disconnect
        d
      end

      def connect_cli
        @post_login.each { |command, block| block ? block.call : (cmd command) }
      end

      def disconnect_cli
        @pre_logout.each { |command, block| block ? block.call : (cmd command, nil) }
      end

      def post_login _post_login=nil, &block
        unless @exec
          @post_login << [_post_login, block]
        end
      end

      def pre_logout _pre_logout=nil, &block
        unless @exec
          @pre_logout <<  [_pre_logout, block]
        end
      end

      def username re=/^(Username|login)/
        @username or @username = re
      end

      def password re=/^Password/
        @password or @password = re
      end

    end
  end
end
