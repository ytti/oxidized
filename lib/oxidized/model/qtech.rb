class QTECH < Oxidized::Model
  comment '! '

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community(?: r[ow])?(?: \d)?) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp-server user .+ auth \S+) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(username .+ password \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable password(?: level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.to_a[1..-2]
    comment cfg.reject { |line| line.match /^  (Copyright |All rights reserved$|Uptime is |Last reboot is )/ }.join
  end

  cmd 'show running-config' do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  cfg :telnet do
    username /^login:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
      cmd 'terminal length 0'
    end
    pre_logout 'exit'
  end
end
