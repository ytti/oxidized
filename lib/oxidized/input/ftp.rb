module Oxidized
  module Input
    require 'net/ftp'
    require 'timeout'
    require_relative 'cli'

    # Handles FTP connections for retrieving configuration files from network devices.
    #
    # This class extends the Input module to provide FTP-specific functionality,
    # including command execution and logging of FTP interactions.
    class FTP < Input
      # Defines the failure handling strategies for different logging levels.
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

      # Establishes a connection to the specified node using FTP.
      #
      # @param node [Node] The node to connect to for FTP operations.
      def connect(node)
        @node = node
        @node.model.cfg['ftp'].each { |cb| instance_exec(&cb) }
        @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-ftp", 'w') if Oxidized.config.input.debug?
        @ftp = Net::FTP.new(@node.ip)
        @ftp.passive = Oxidized.config.input.ftp.passive
        @ftp.login @node.auth[:username], @node.auth[:password]
        connected?
      end

      # Checks if the FTP connection is established and not closed.
      #
      # @return [Boolean] True if connected, false otherwise.
      def connected?
        @ftp && (not @ftp.closed?)
      end

      # Retrieves a file from the FTP server.
      #
      # @param file [String] The name of the file to retrieve.
      # @return [void]
      def cmd(file)
        Oxidized.logger.debug "FTP: #{file} @ #{@node.name}"
        @ftp.getbinaryfile file, nil
      end

      # Sends a command using a provided procedure.
      #
      # @param my_proc [Proc] The procedure to execute.
      # @return [void]
      def send(my_proc)
        my_proc.call
      end

      # Provides an output string (currently empty).
      #
      # @return [String] An empty string.
      def output
        ""
      end

      private

      # Closes the FTP connection and log file if debugging is enabled.
      #
      # @return [void]
      def disconnect
        @ftp.close
      # @!visibility private
      # rescue Errno::ECONNRESET, IOError
      ensure
        @log.close if Oxidized.config.input.debug?
      end
    end
  end
end
