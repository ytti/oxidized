module Oxidized
  class Input
    module CLI
      attr_reader :node

      def initialize
        @post_login = []
        @pre_logout = []
        @username, @password, @exec = nil
      end

      def get
        connect_cli
        d = node.model.get
        disconnect
        d
      rescue PromptUndetect
        disconnect
        raise
      end

      def connect_cli
        Oxidized.logger.debug "lib/oxidized/input/cli.rb: Running post_login commands at #{node.name}"
        @post_login.each do |command, block|
          Oxidized.logger.debug "lib/oxidized/input/cli.rb: Running post_login command: #{command.inspect}, block: #{block.inspect} at #{node.name}"
          block ? block.call : (cmd command)
        end
      end

      def disconnect_cli
        Oxidized.logger.debug "lib/oxidized/input/cli.rb Running pre_logout commands at #{node.name}"
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
