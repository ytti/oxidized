module Oxidized
  require 'fileutils'
  FileUtils.mkdir_p Config::Root
  CFG.username = 'username'
  CFG.password = 'password'
  CFG.model    = 'junos'
  CFG.interval = 60
  CFG.log      = File.join Config::Root, 'log'
  CFG.debug    = false
  CFG.threads  = 30
  CFG.timeout  = 5
  CFG.prompt   = /^([\w\.\-@]{3,30}[#>]\s?)$/ 
  CFG.rest     = 8888
  CFG.input    = {
    :default => 'ssh',
  }
  CFG.output    = {
    :default => 'git',
  }
  CFG.source   = {
    :default => 'csv',
  }
  CFG.model_map = {
    'cisco'   => 'ios',
    'juniper' => 'junos',
  }
  CFG.save
end
