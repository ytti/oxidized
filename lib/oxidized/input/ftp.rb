module Oxidized
  require 'net/ftp'
  require 'timeout'
  require 'oxidized/input/cli'
  class FTP < Input
    RescueFail = {
      :debug => [],
      :warn => [],
    }
    include Input::CLI

    def connect node
      @node       = node
      @node.model.cfg['ftp'].each { |cb| instance_exec(&cb) }
      @log = File.open(Oxidized::Config::Log + "/#{@node.ip}-ftp", 'w') if Oxidized.config.input.debug?
      @ftp = Net::FTP.new(@node.ip)
      @ftp.passive = false
      @ftp.login  @node.auth[:username], @node.auth[:password]
      connected?
    end

    def connected?
      @ftp and not @ftp.closed?
    end

    def cmd file
      Oxidized.logger.debug "FTP: #{file} @ #{@node.name}"
      @ftp.getbinaryfile file, nil
    end

    private

    def disconnect
      @ftp.close
    #rescue Errno::ECONNRESET, IOError
    ensure
      @log.close if Oxidized.config.input.debug?
    end

  end
end
