class DNOS < Oxidized::Model
  # Force10 DNOS model #

  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.gsub! /(uptime is)(\s.+)/, '\\1 <removed>' # Omit changing uptime info
    cfg.each_line.to_a[2..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /password (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^(tacacs-server key \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show inventory media' do |cfg|
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
