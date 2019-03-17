module Oxidized
  require 'asetus'
  class NoConfig < OxidizedError; end
  class InvalidConfig < OxidizedError; end
  class Config
    Root      = ENV['OXIDIZED_HOME'] || File.join(ENV['HOME'], '.config', 'oxidized')
    Crash     = File.join(ENV['OXIDIZED_LOGS'] || Root, 'crash')
    Log       = File.join(ENV['OXIDIZED_LOGS'] || Root, 'logs')
    InputDir  = File.join Directory, %w[lib oxidized input]
    OutputDir = File.join Directory, %w[lib oxidized output]
    ModelDir  = File.join Directory, %w[lib oxidized model]
    SourceDir = File.join Directory, %w[lib oxidized source]
    HookDir   = File.join Directory, %w[lib oxidized hook]
    Sleep     = 1

    def self.load(cmd_opts = {})
      asetus = Asetus.new(name: 'oxidized', load: false, key_to_s: true)
      Oxidized.asetus = asetus

      asetus.default.username      = 'username'
      asetus.default.password      = 'password'
      asetus.default.model         = 'junos'
      asetus.default.resolve_dns   = true # if false, don't resolve DNS to IP
      asetus.default.interval      = 3600
      asetus.default.use_syslog    = false
      asetus.default.debug         = false
      asetus.default.threads       = 30
      asetus.default.timeout       = 20
      asetus.default.retries       = 3
      asetus.default.prompt        = /^([\w.@-]+[#>]\s?)$/
      asetus.default.rest          = '127.0.0.1:8888' # or false to disable
      asetus.default.next_adds_job = false            # if true, /next adds job, so device is fetched immmeiately
      asetus.default.vars          = {}               # could be 'enable'=>'enablePW'
      asetus.default.groups        = {}               # group level configuration
      asetus.default.models        = {}               # model level configuration
      asetus.default.pid           = File.join(Oxidized::Config::Root, 'pid')

      asetus.default.crash.directory = File.join(Oxidized::Config::Root, 'crashes')
      asetus.default.crash.hostnames = false

      asetus.default.stats.history_size = 10
      asetus.default.input.default      = 'ssh, telnet'
      asetus.default.input.debug        = false # or String for session log file
      asetus.default.input.ssh.secure   = false # complain about changed certs
      asetus.default.input.ftp.passive  = true  # ftp passive mode
      asetus.default.input.utf8_encoded = true  # configuration is utf8 encoded or ascii-8bit

      asetus.default.output.default = 'file'  # file, git
      asetus.default.source.default = 'csv'   # csv, sql

      asetus.default.model_map = {
        'juniper' => 'junos',
        'cisco'   => 'ios'
      }

      begin
        asetus.load # load system+user configs, merge to Config.cfg
      rescue StandardError => error
        raise InvalidConfig, "Error loading config: #{error.message}"
      end

      raise NoConfig, 'edit ~/.config/oxidized/config' if asetus.create

      # override if comand line flag given
      asetus.cfg.debug = cmd_opts[:debug] if cmd_opts[:debug]

      asetus
    end
  end

  class << self
    attr_accessor :mgr, :Hooks
  end
end
