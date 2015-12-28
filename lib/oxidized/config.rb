module Oxidized
  require 'asetus'
  class NoConfig < OxidizedError; end
  class InvalidConfig < OxidizedError; end
  class Config
    Root      = File.join ENV['HOME'], '.config', 'oxidized'
    Crash     = File.join Root, 'crash'
    InputDir  = File.join Directory, %w(lib oxidized input)
    OutputDir = File.join Directory, %w(lib oxidized output)
    ModelDir  = File.join Directory, %w(lib oxidized model)
    SourceDir = File.join Directory, %w(lib oxidized source)
    HookDir   = File.join Directory, %w(lib oxidized hook)
    Sleep     = 1
  end
  class << self
    attr_accessor :mgr, :Hooks
  end
  CFGS = Asetus.new :name=>'oxidized', :load=>false, :key_to_s=>true
  CFGS.default.username      = 'username'
  CFGS.default.password      = 'password'
  CFGS.default.model         = 'junos'
  CFGS.default.interval      = 3600
  CFGS.default.log           = File.join Config::Root, 'log'
  CFGS.default.debug         = false
  CFGS.default.threads       = 30
  CFGS.default.timeout       = 20
  CFGS.default.retries       = 3
  CFGS.default.prompt        = /^([\w.@-]+[#>]\s?)$/
  CFGS.default.rest          = '127.0.0.1:8888' # or false to disable
  CFGS.default.vars          = {}             # could be 'enable'=>'enablePW'
  CFGS.default.groups        = {}             # group level configuration
  CFGS.default.database      = 'oxidized_database.db'

  CFGS.default.input.default    = 'ssh, telnet'
  CFGS.default.input.debug      = false # or String for session log file
  CFGS.default.input.ssh.secure = false # complain about changed certs

  CFGS.default.output.default = 'file'  # file, git
  CFGS.default.source.default = 'csv'   # csv, sql

  CFGS.default.model_map = {
    'cisco'   => 'ios',
    'juniper' => 'junos',
  }

  begin
    CFGS.load # load system+user configs, merge to Config.cfg
  rescue => error
    raise InvalidConfig, "Error loading config: #{error.message}"
  ensure
    CFG = CFGS.cfg  # convenienence, instead of Config.cfg.password, CFG.password
  end

  Log.level = Logger::INFO unless CFG.debug
  raise NoConfig, 'edit ~/.config/oxidized/config' if CFGS.create
  Log.file = CFG.log if CFG.log

end
