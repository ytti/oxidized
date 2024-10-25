module Oxidized
  require 'asetus'
  require 'oxidized/error/noconfig'
  require 'oxidized/error/invalidconfig'

  # Handles configuration management for the Oxidized application.
  class Config
    # Root directory for Oxidized configuration.
    ROOT       = ENV['OXIDIZED_HOME'] || File.join(Dir.home, '.config', 'oxidized')
    # Directory for crash logs.
    CRASH      = File.join(ENV['OXIDIZED_LOGS'] || ROOT, 'crash')
    # Directory for general logs.
    LOG        = File.join(ENV['OXIDIZED_LOGS'] || ROOT, 'logs')
    # Directory for input plugins.
    INPUT_DIR  = File.join Directory, %w[lib oxidized input]
    # Directory for output plugins.
    OUTPUT_DIR = File.join Directory, %w[lib oxidized output]
    # Directory for models.
    MODEL_DIR  = File.join Directory, %w[lib oxidized model]
    # Directory for source plugins.
    SOURCE_DIR = File.join Directory, %w[lib oxidized source]
    # Directory for hooks.
    HOOK_DIR   = File.join Directory, %w[lib oxidized hook]
    # Default sleep interval for threads.
    SLEEP      = 1

    # Loads the configuration using the Asetus gem.
    #
    # This method initializes and loads the Oxidized configuration from a file,
    # applies default settings, and handles custom command-line options.
    #
    # @param cmd_opts [Hash] options passed from the command line or other sources.
    # @option cmd_opts [String] :home_dir the custom home directory for Oxidized.
    # @option cmd_opts [String] :config_file the custom configuration file name.
    # @option cmd_opts [Boolean] :debug whether to enable debug mode.
    #
    # @return [Asetus] returns the Asetus configuration object.
    #
    # @raise [InvalidConfig] if there is an error loading the configuration.
    # @raise [NoConfig] if no configuration is found and the configuration is being created for the first time.
    def self.load(cmd_opts = {})
      # @!visibility private
      # Determine the user directory and config file to use
      usrdir = File.expand_path(cmd_opts[:home_dir] || Oxidized::Config::ROOT)
      cfgfile = cmd_opts[:config_file] || 'config'

      # @!visibility private
      # Configuration file with full path as a class instance variable
      @configfile = File.join(usrdir, cfgfile)
      asetus = Asetus.new(name: 'oxidized', load: false, key_to_s: true, usrdir: usrdir, cfgfile: cfgfile)
      Oxidized.asetus = asetus

      # @!visibility private
      # Default configuration values
      asetus.default.username      = 'username'
      asetus.default.password      = 'password'
      asetus.default.model         = 'junos'
      asetus.default.resolve_dns   = true # if false, don't resolve DNS to IP
      asetus.default.interval      = 3600
      asetus.default.use_syslog    = false
      asetus.default.debug         = false
      asetus.default.run_once      = false
      asetus.default.threads       = 30
      asetus.default.use_max_threads = false
      asetus.default.timeout       = 20
      asetus.default.retries       = 3
      asetus.default.prompt        = /^([\w.@-]+[#>]\s?)$/
      asetus.default.rest          = '127.0.0.1:8888' # or false to disable
      asetus.default.next_adds_job = false            # if true, /next adds job, so device is fetched immmeiately
      asetus.default.vars          = {}               # could be 'enable'=>'enablePW'
      asetus.default.groups        = {}               # group level configuration
      asetus.default.group_map     = {}               # map aliases of groups to names
      asetus.default.models        = {}               # model level configuration
      asetus.default.pid           = File.join(Oxidized::Config::ROOT, 'pid')

      # @!visibility private
      # Default crash configurations
      asetus.default.crash.directory = File.join(Oxidized::Config::ROOT, 'crashes')
      asetus.default.crash.hostnames = false

      # @!visibility private
      # Default statistics settings
      asetus.default.stats.history_size = 10

      # @!visibility private
      # Default input plugin settings
      asetus.default.input.default      = 'ssh, telnet'
      asetus.default.input.debug        = false # or String for session log file
      asetus.default.input.ssh.secure   = false # complain about changed certs
      asetus.default.input.ftp.passive  = true  # ftp passive mode
      asetus.default.input.utf8_encoded = true  # configuration is utf8 encoded or ascii-8bit

      # @!visibility private
      # Default output and source plugins
      asetus.default.output.default = 'file'  # file, git
      asetus.default.source.default = 'csv'   # csv, sql

      # @!visibility private
      # Map for model aliases
      asetus.default.model_map = {
        'juniper' => 'junos',
        'cisco'   => 'ios'
      }

      # @!visibility private
      # Load the configuration, catching any errors
      begin
        asetus.load # load system+user configs, merge to Config.cfg
      rescue StandardError => e
        raise InvalidConfig, "Error loading config: #{e.message}"
      end


      # @!visibility private
      # If the configuration is being created for the first time, raise NoConfig
      raise NoConfig, "edit #{@configfile}" if asetus.create

      # @!visibility private
      # Override debug setting if provided in the command line options
      asetus.cfg.debug = cmd_opts[:debug] if cmd_opts[:debug]

      asetus
    end

    class << self
      attr_reader :configfile
    end
  end

  # Class-level attributes for manager and hooks.
  class << self
    # @!attribute [rw] mgr
    #   @return [Object] The manager instance.
    attr_accessor :mgr

    # @!attribute [rw] hooks
    #   @return [Object] The hooks instance.
    attr_accessor :hooks
  end
end
