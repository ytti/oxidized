module Oxidized
  module Input
    class Input
      # Provides methods for handling command-line interface (CLI) interactions
      # with network devices.
      #
      # This module supports connection management, login/logout sequences,
      # and execution of pre- and post-login commands.
      module CLI
        # The current node being processed.
        #
        # @!attribute [rw] node
        # @return [Node] The node object associated with the CLI input.
        attr_reader :node

        # Initializes a new instance of the CLI module.
        #
        # This constructor sets up the necessary instance variables for
        # managing login credentials and command execution.
        def initialize
          @post_login = []
          @pre_logout = []
          @username, @password, @exec = nil
        end

        # Retrieves the configuration data for the current node.
        #
        # @return [Object] The configuration data for the node.
        # @raise [PromptUndetect] If the expected prompt is not detected.
        def get
          connect_cli
          d = node.model.get
          disconnect
          d
        rescue PromptUndetect
          disconnect
          raise
        end

        # Executes post-login commands for the current node.
        def connect_cli
          Oxidized.logger.debug "lib/oxidized/input/cli.rb: Running post_login commands at #{node.name}"
          @post_login.each do |command, block|
            Oxidized.logger.debug "lib/oxidized/input/cli.rb: Running post_login command: #{command.inspect}, block: #{block.inspect} at #{node.name}"
            block ? block.call : (cmd command)
          end
        end

        # Executes pre-logout commands for the current node.
        def disconnect_cli
          Oxidized.logger.debug "lib/oxidized/input/cli.rb Running pre_logout commands at #{node.name}"
          @pre_logout.each { |command, block| block ? block.call : (cmd command, nil) }
        end

        # Adds a post-login command to the list of commands to execute.
        #
        # @param cmd [String] The command to execute.
        # @param block [Proc] An optional block to execute.
        def post_login(cmd = nil, &block)
          return if @exec

          @post_login << [cmd, block]
        end

        # Adds a pre-logout command to the list of commands to execute.
        #
        # @param cmd [String] The command to execute.
        # @param block [Proc] An optional block to execute.
        def pre_logout(cmd = nil, &block)
          return if @exec

          @pre_logout << [cmd, block]
        end

        # Sets or retrieves the regex used for matching the username prompt.
        #
        # @param regex [Regexp] An optional regex to set for username matching.
        # @return [Regexp] The regex used for matching the username prompt.
        def username(regex = /^(Username|login)/)
          @username || (@username = regex)
        end

        # Sets or retrieves the regex used for matching the password prompt.
        #
        # @param regex [Regexp] An optional regex to set for password matching.
        # @return [Regexp] The regex used for matching the password prompt.
        def password(regex = /^Password/)
          @password || (@password = regex)
        end

        # Performs the login process using the defined prompts.
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
end
