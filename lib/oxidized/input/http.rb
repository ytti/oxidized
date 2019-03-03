module Oxidized
  require_relative "cli"

  begin
    require "mechanize"
  rescue LoadError
    raise OxidizedError, "mechanize not found: sudo gem install mechanize"
  end

  class HTTP < Input
    include Input::CLI

    def connect(node)
      @node = node
      @m    = Mechanize.new
      @log  = File.open(Oxidized::Config::Log + "/#{@node.ip}-http", "w") if Oxidized.config.input.debug?

      @node.model.cfg["http"].each { |cb| instance_exec(&cb) }

      url = URI::HTTP.build host: @node.ip, path: @main_page
      @m_page = @m.get(url.to_s)
      login
    end

    def cmd(callback)
      instance_exec(&callback)
    end

    private

    def log(str)
      @log&.write(str)
    end

    def disconnect
      @log.close if Oxidized.config.input.debug?
    end
  end
end
