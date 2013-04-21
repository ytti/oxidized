module Oxidized
  class Input
    module CLI
  
      def initialize
        @post_login = []
        @pre_logout = []
      end

      def get
        @post_login.each { |command| cmd command }
        d = @node.model.get
        disconnect
        d
      end
  
      def post_login _post_login
        @post_login << _post_login unless @exec
      end
  
      def pre_logout _pre_logout
        @pre_logout << _pre_logout unless @exec
      end
    end
  end
end
