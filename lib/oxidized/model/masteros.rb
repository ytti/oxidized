class MasterOS < Oxidized::Model
  # MRV MasterOS model #

  comment '!'

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /username (\S+) password encrypted (\S+) class (\S+).*/, '<secret hidden>'
    cfg
  end

  cmd :all do |cfg|
    cfg.cut_both
    cfg.gsub /^(! Configuration ).*/, '!'
  end

  cmd 'show inventory' do |cfg|
    comment cfg.cut_tail
  end

  cmd 'show plugins' do |cfg|
    comment cfg
  end

  cmd 'show hw-config' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cfg :telnet, :ssh do
    post_login 'no pager'
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    pre_logout 'exit'
  end
end
