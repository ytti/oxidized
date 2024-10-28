module Oxidized
  module Input
    require "oxidized/input/cli"

    # Handles execution of commands on network devices using the command line interface (CLI).
    #
    # This class extends the functionality of the Input module by allowing
    # command execution via system calls and logging.
    class Exec < Input
      include Input::CLI

      # Establishes a connection to the specified node and executes its
      # associated commands.
      #
      # @param node [Node] The node to connect to and execute commands on.
      def connect(node)
        @node = node
        @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-exec", "w") if Oxidized.config.input.debug?
        @node.model.cfg["exec"].each { |cb| instance_exec(&cb) }
      end

      # Executes a command string in the system shell.
      #
      # @param cmd_str [String] The command string to execute.
      # @return [String] The output of the executed command.
      def cmd(cmd_str)
        Oxidized.logger.debug "EXEC: #{cmd_str} @ #{@node.name}"
        # I'd really like to do popen3 with separate arguments, but that would
        # require refactoring cmd to take parameters
        %x(#{cmd_str})
      end

      private

      # Closes the log file if debugging is enabled.
      #
      # @return [Boolean] Always returns true.
      def disconnect
        true
      ensure
        @log.close if Oxidized.config.input.debug?
      end
    end
  end
end
