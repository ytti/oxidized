class ACSW < Oxidized::Model
  prompt /([\w.@()\/\\-]+[#>]\s?)/
  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username \S+ privilege \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(username \S+ password \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(username \S+ secret \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret) \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*wpa-psk ascii \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*key 7) (.*)/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server key \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(crypto isakmp key) (\S+) (.*)/, '\\1 <secret hidden> \\3'
    cfg.gsub! /^(.*key 1 md5) (\d.+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*standby \d.+authentication).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*version 2c).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1]
    cfg = cfg.reject { |line| line.match /^ntp clock-period / }.join
    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
    cfg.gsub! /^ tunnel mpls traffic-eng bandwidth[^\n]*\n*(
                  (?: [^\n]*\n*)*
                  tunnel mpls traffic-eng auto-bw)/mx, '\1'
    cfg.gsub! /^([\s\t!]*Last configuration change ).*/, ''
    cfg.gsub! /^([\s\t!]*NVRAM config last ).*/, ''
    cfg
  end

  cfg :telnet do
    username /.*login:/
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
    pre_logout 'exit'
  end
end
