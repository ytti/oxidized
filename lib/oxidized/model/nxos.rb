class NXOS < Oxidized::Model

  prompt /^(\r?[\w.@_()-]+[#]\s?)$/
  comment '! '

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp-server user (\S+) (\S+) auth (\S+)) (\S+) (priv) (\S+)/, '\\1 <configuration removed> '
    cfg.gsub! /^(username \S+ password \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(radius-server key).*/, '\\1 <secret hidden>'
    cfg
  end
  
  cmd 'show version' do |cfg|
    cfg = cfg.each_line.take_while { |line| not line.match(/uptime/i) }
    comment cfg.join ""
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end 

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^!Time:[^\n]*\n/, ''
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^login:/
    password /^Password:/
  end
end
