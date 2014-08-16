module Oxidized
  class CLI
    require 'oxidized'
    require 'slop'

    def run
      Process.daemon if @opts[:daemonize]
      begin
        Oxidized.new
      rescue => error
        crash error
        raise
      end
    end

    private

    def initialize
      Log.info "Oxidized starting, running as pid #{$$}"
      _args, @opts = parse_opts
      CFG.debug = true if @opts[:debug]
    end

    def crash error
      Log.fatal "Oxidized crashed, crashfile written in #{Config::Crash}"
      open Config::Crash, 'w' do |file|
        file.puts '-' * 50
        file.puts Time.now.utc
        file.puts error.message + ' [' + error.class.to_s + ']'
        file.puts '-' * 50
        file.puts error.backtrace
        file.puts '-' * 50
      end
    end

    def parse_opts
      opts = Slop.new(:help=>true) do
        on 'd', 'debug', 'turn on debugging'
        on 'daemonize',  'Daemonize/fork the process'
      end
      [opts.parse!, opts]
    end
  end
end
