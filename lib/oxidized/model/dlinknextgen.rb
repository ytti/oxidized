class DlinkNextGen < Oxidized::Model
  using Refinements

  # D-LINK next generation cli Switches
  # Add support DXS-1210-12SC

  prompt /[\w.@()\/-]+[#>]\s?$/
  comment '# '

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  cmd :secret do |cfg|
    cfg.gsub! /(password) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(snmp-server group) (\S+) (v.*)/, '\\1 <secret hidden> \\3'
    cfg.gsub! /(snmp-server community) (\S+) (v.*)/, '\\1 <secret hidden> \\3'
    cfg
  end

  # "show switch" doesn't exist on DXS-1210-28T rev A1 Firmware: Build 1.00.024; not figured out how to run "show version" so running both
  cmd 'show switch' do |cfg|
    cfg.gsub! /^\s+System Time\s.+/, '' # Omit constantly changing uptime info
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show vlan' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(snmp-server community ["\w]+) \S+/, '\\1 <removed>'
    cfg.gsub! /^(username [\w.@-]+ privilege \d{1,2} password \d{1,2}) \S+/, '\\1 <removed>'
    cfg.gsub! /^(!System Up Time).*/, '\\1 <removed>'
    cfg.gsub! /^(!Current SNTP Synchronized Time:).*/, '\\1 <removed>'
    cfg.gsub! /^(\s+ppp (chap|pap) password \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  cfg :telnet do
    username /\r*([\w\s.@()\/:-]+)?([Uu]ser[Nn]ame|[Ll]ogin):/
    password /\r*[Pp]ass[Ww]ord:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 255'
    pre_logout 'logout'
  end
end
