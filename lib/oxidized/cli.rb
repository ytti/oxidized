module Oxidized
  class CLI
    require 'oxidized'
    require 'slop'
    class CLIError < OxidizedError; end
    class NoConfig < CLIError; end

    def run
      Process.daemon unless CFG.debug
      begin
        Oxidized.new
      rescue => error
        crash error
        raise
      end
    end

    private

    def initialize
      raise NoConfig, 'edit ~/.config/oxidized/config' if CFGS.create
      _args, opts = parse_opts
      CFG.debug = true if opts[:debug]
    end

    def crash error
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
      end
      [opts.parse!, opts]
    end
  end
end
