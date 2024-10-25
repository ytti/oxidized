module Oxidized
  # The CLI class manages the command-line interface for the Oxidized application.
  # It handles command-line options, process management, and error logging.
  class CLI
    require 'slop'
    require 'oxidized'
    require 'English'

    # Executes the main logic for running the Oxidized application.
    #
    # @return [void]
    def run
      check_pid
      Process.daemon if @opts[:daemonize]
      write_pid
      begin
        Oxidized.logger.info "Oxidized starting, running as pid #{$PROCESS_ID}"
        Oxidized.new
      rescue StandardError => e
        crash e
        raise
      end
    end

    private

    # Initializes the CLI with parsed command-line options and configuration.
    def initialize
      _args, @opts = parse_opts

      Config.load(@opts)
      Oxidized.setup_logger

      @pidfile = File.expand_path(Oxidized.config.pid)
    end

    # Logs a fatal error and writes crash information to a crash file.
    #
    # @param error [StandardError] The error that caused the crash.
    #
    # @return [void]
    def crash(error)
      Oxidized.logger.fatal "Oxidized crashed, crashfile written in #{Config::CRASH}"
      File.open Config::CRASH, 'w' do |file|
        file.puts '-' * 50
        file.puts Time.now.utc
        file.puts error.message + ' [' + error.class.to_s + ']'
        file.puts '-' * 50
        file.puts error.backtrace
        file.puts '-' * 50
      end
    end

    # Parses command-line options and returns them.
    #
    # @return [Array] An array containing the arguments and options.
    def parse_opts
      opts = Slop.parse do |opt|
        opt.on '-d', '--debug', 'turn on debugging'
        opt.on '--daemonize', 'Daemonize/fork the process'
        opt.string '--home-dir', 'Oxidized home dir', default: nil
        opt.string '--config-file', 'Oxidized config file', default: nil
        opt.on '-h', '--help', 'show usage' do
          puts opt
          exit
        end
        opt.on '--show-exhaustive-config', 'output entire configuration, including defaults' do
          asetus = Config.load
          puts asetus.to_yaml asetus.cfg
          Kernel.exit
        end
        opt.on '-v', '--version', 'show version' do
          puts Oxidized::VERSION_FULL
          Kernel.exit
        end
      end
      [opts.arguments, opts]
    end

    # @!attribute [rw] pidfile
    # @return [String] The path to the PID file.
    attr_reader :pidfile

    # Checks if the PID file is present.
    #
    # @return [Boolean] True if the PID file exists; otherwise, false.
    def pidfile?
      !!pidfile
    end

    # Writes the current process ID to the PID file.
    #
    # @return [void]
    def write_pid
      return unless pidfile?

      begin
        File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) { |f| f.write(Process.pid.to_s) }
        at_exit { FileUtils.rm_f(pidfile) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end

    # Checks the status of the PID file and verifies if a process is already running.
    #
    # @return [void]
    def check_pid
      return unless pidfile?

      case pid_status(pidfile)
      when :running, :not_owned
        puts "A server is already running. Check #{pidfile}"
        exit(1)
      when :dead
        File.delete(pidfile)
      end
    end

    # Determines the status of the process associated with the PID file.
    #
    # @param pidfile [String] The path to the PID file.
    #
    # @return [Symbol] The status of the process: :running, :dead, :not_owned, or :exited.
    def pid_status(pidfile)
      return :exited unless File.exist?(pidfile)

      pid = ::File.read(pidfile).to_i
      return :dead if pid.zero?

      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end
  end
end
