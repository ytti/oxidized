module Oxidized
  require 'net/ftp'
  require 'timeout'
  require_relative 'cli'

  class FTP < Input
    RescueFail = {
      :debug => [
        #Net::SSH::Disconnect,
      ],
      :warn => [
        #RuntimeError,
        #Net::SSH::AuthenticationFailed,
      ],
    }
    include Input::CLI

    def connect node
      @node       = node
      @node.model.cfg['ftp'].each { |cb| instance_exec(&cb) }
      @log = File.open(CFG.input.debug?.to_s + '-ftp', 'w') if CFG.input.debug?
      @ftp = Net::FTP.new @node.ip, @node.auth[:username], @node.auth[:password]
      connected?
    end

    def connected?
      @ftp and not @ftp.closed?
    end

    def cmd file
      Log.debug "FTP: #{file} @ #{@node.name}"
      @ftp.getbinaryfile file, nil
    end

    # meh not sure if this is the best way, but perhaps better than not implementing send
    def send my_proc
      my_proc.call
    end

    def output
      ""
    end

    private

    def disconnect
      @ftp.close
    #rescue Errno::ECONNRESET, IOError
    ensure
      @log.close if CFG.input.debug?
    end

  end
end
