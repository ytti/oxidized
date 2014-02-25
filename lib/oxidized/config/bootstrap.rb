module Oxidized
  require 'fileutils'
  FileUtils.mkdir_p Config::Root
  CFG.username = 'username'
  CFG.password = 'password'
  CFG.model    = 'junos'
  CFG.interval = 3600
  CFG.log      = File.join Config::Root, 'log'
  CFG.debug    = false
  CFG.threads  = 30
  CFG.timeout  = 5
  CFG.prompt   = /^([\w.@-]+[#>]\s?)$/
  CFG.rest     = '0.0.0.0:8888'
  CFG.vars     = {
    :enable  => 'enablePW',
  }
  CFG.input   = {
    :default  => 'ssh, telnet',
    :ssh      =>  {
      :secure => false,
    }
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
end
