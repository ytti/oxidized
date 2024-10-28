module Oxidized
  module Input
    require 'stringio'
    require_relative 'cli'

    begin
      require 'net/tftp'
    rescue LoadError
      raise OxidizedError, 'net/tftp not found: sudo gem install net-tftp'
    end

    # Manages TFTP operations for fetching configurations from network devices.
    #
    # This class extends the Input module and provides methods for connecting
    # to devices and retrieving files using TFTP.
    class TFTP < Input
      include Input::CLI

      # Establishes a TFTP session with the specified node.
      #
      # @param node [Node] The node to connect to for TFTP operations.
      # @note TFTP utilizes UDP, there is not a connection. We simply specify an IP and send/receive data.
      def connect(node)
        @node = node

        @node.model.cfg['tftp'].each { |cb| instance_exec(&cb) }
        @log = File.open(Oxidized::Config::LOG + "/#{@node.ip}-tftp", 'w') if Oxidized.config.input.debug?
        @tftp = Net::TFTP.new @node.ip
      end

      # Retrieves a file from the TFTP server associated with the node.
      #
      # @param file [String] The name of the file to download.
      # @return [String] The contents of the downloaded file.
      def cmd(file)
        Oxidized.logger.debug "TFTP: #{file} @ #{@node.name}"
        config = StringIO.new
        @tftp.getbinary file, config
        config.rewind
        config.read
      end

      private

      # Cleans up after the TFTP session.
      #
      # @return [Boolean] Always returns true, as TFTP uses UDP and has no connection to close.
      def disconnect
        true
      ensure
        @log.close if Oxidized.config.input.debug?
      end
    end
  end
end
