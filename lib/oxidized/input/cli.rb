module Oxidized
  class Input
    module CLI
  
      def initialize
        @post_login = []
        @pre_logout = []
      end

      def get
        @post_login.each { |command, block| block ? block.call : (cmd command) }
        d = @node.model.get
        disconnect
        d
      end

      def disconnect_cli
        @pre_logout.each { |command, block| block ? block.call : (cmd command) }
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
    end
  end
end
