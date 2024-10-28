module Oxidized
  module Input
    require 'net/ssh'
    require 'net/scp'
    require 'timeout'
    require_relative 'cli'

    # Manages SCP connections to network devices for file transfers.
    #
    # This class extends the Input module and provides methods for connecting
    # to devices, downloading files via SCP, and handling authentication.
    class SCP < Input
      # A hash defining exceptions that may be raised during SCP operations.
      RESCUE_FAIL = {
        debug: [
          # @!visibility private
          # Net::SSH::Disconnect,
        ],
        warn:  [
          # @!visibility private
          # RuntimeError,
          # Net::SSH::AuthenticationFailed,
        ]
      }.freeze
      include Input::CLI

      # Establishes an SCP connection to the specified node.
      #
      # @param node [Node] The node to connect to for SCP operations.
      # @return [Boolean] True if connection is successful, otherwise raises an error.
      def connect(node)
        @node = node
        @node.model.cfg['scp'].each { |cb| instance_exec(&cb) }
        @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-scp", 'w') if Oxidized.config.input.debug?
        @ssh = Net::SSH.start(@node.ip, @node.auth[:username], password: @node.auth[:password])
        connected?
      end

      # Checks if the SCP connection is currently open.
      #
      # @return [Boolean] True if connected, false otherwise.
      def connected?
        @ssh && (not @ssh.closed?)
      end

      # Downloads a file from the connected node using SCP.
      #
      # @param file [String] The path to the file to download from the node.
      # @return [void]
      def cmd(file)
        Oxidized.logger.debug "SCP: #{file} @ #{@node.name}"
        @ssh.scp.download!(file)
      end

      # Sends data using a provided procedure.
      #
      # @param my_proc [Proc] The procedure to execute.
      # @return [void]
      def send(my_proc)
        my_proc.call
      end

      # Returns an empty output string.
      #
      # @return [String] An empty string.
      def output
        ""
      end

      private

      # Closes the SCP connection and log file if debugging is enabled.
      #
      # @return [void]
      def disconnect
        @ssh.close
      ensure
        @log.close if Oxidized.config.input.debug?
      end
    end
  end
end
