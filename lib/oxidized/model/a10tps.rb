class A10TPS < Oxidized::Model
  # A10 ACOS model Thunder TPS

  comment '! '

  # ACOS prompt changes depending on the state of the device
  prompt /^([-\w.\/:?\[\]()]+[#>]\s?)$/

  cmd :secret do |cfg|
    cfg.gsub!(/community read encrypted (\S+)/, 'community read encrypted <hidden>') # snmp
    cfg.gsub!(/secret encrypted (\S+)/, 'secret encrypted <hidden>') # tacacs-server
    cfg.gsub!(/password encrypted (\S+)/, 'password encrypted <hidden>') # user
    cfg.gsub!(/auth-password encrypted (\S+)/, 'auth-password encrypted <hidden>') # Some other password
    cfg
  end

  # Show version shows to much information not related to the version
  # and depending on time/data/etc.
  cmd 'show version' do |cfg|
    cfg.gsub! /\s(Free storage).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Total System Memory [0-9]* Mbyte, Free Memory).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Current time is).*/, ' \\1 <removed>'
    cfg.gsub! /\s(The system has been up).*/, ' \\1 <removed>'
    comment cfg
  end

  cmd 'show bootimage' do |cfg|
    comment cfg
  end

  cmd 'show license' do |cfg|
    comment cfg
  end

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg
  end

  ## Enhance configuration by removing timestamp 
  cmd 'show running-config partition-config all' do |cfg|
    cfg.gsub! /(Current configuration).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last updated at).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last saved at).*/, '\\1 <removed>'
    cfg.gsub! /(Configuration last synchronized at).*/, '\\1 <removed>'
    cfg
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout "exit\nexit\nY\r\n"
  end
end
