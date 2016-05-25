module Oxidized
  class CLI
    require 'slop'
    require 'oxidized'

    def run
      check_pid
      Process.daemon if @opts[:daemonize]
      write_pid
      begin
        Oxidized.logger.info "Oxidized starting, running as pid #{$$}"
        Oxidized.new
      rescue => error
        crash error
        raise
      end
    end

    private

    def initialize
      _args, @opts = parse_opts

      Config.load(@opts)
      Oxidized.setup_logger

      @pidfile = File.expand_path(Oxidized.config.pid)
    end

    def crash error
      Oxidized.logger.fatal "Oxidized crashed, crashfile written in #{Config::Crash}"
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
        on 'v', 'version', 'show version' do
          puts Oxidized::VERSION
          Kernel.exit
        end
      end
      [opts.parse!, opts]
    end

    def pidfile
      @pidfile
    end

    def pidfile?
      !!pidfile
    end

    def write_pid
      if pidfile?
        begin
          File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
          at_exit { File.delete(pidfile) if File.exists?(pidfile) }
        rescue Errno::EEXIST
          check_pid
          retry
        end
      end
    end

    def check_pid
      if pidfile?
        case pid_status(pidfile)
        when :running, :not_owned
          puts "A server is already running. Check #{pidfile}"
          exit(1)
        when :dead
          File.delete(pidfile)
        end
      end
    end

    def pid_status(pidfile)
      return :exited unless File.exists?(pidfile)
      pid = ::File.read(pidfile).to_i
      return :dead if pid == 0
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end
  end
end
