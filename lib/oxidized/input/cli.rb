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

      def post_login(cmd = nil, &block)
        return if @exec

        @post_login << [cmd, block]
      end

      def pre_logout(cmd = nil, &block)
        return if @exec

        @pre_logout << [cmd, block]
      end

      def username(regex = /^(Username|login)/)
        @username || (@username = regex)
      end

      def password(regex = /^Password/)
        @password || (@password = regex)
      end

      def login
        match_re = [@node.prompt]
        match_re << @username if @username
        match_re << @password if @password
        until (match = expect(match_re)) == @node.prompt
          cmd(@node.auth[:username], nil) if match == @username
          cmd(@node.auth[:password], nil) if match == @password
          match_re.delete match
        end
      end
    end
  end
end
