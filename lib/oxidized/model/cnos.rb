# model for Centec Networks CNOS based switches
class CNOS < Oxidized::Model
  comment '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[0..-2].join
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub!(/(snmp-server community )(\S+)/, '\1<hidden>')
    cfg.gsub!(/key type private.+key string end/m, '<private key hidden>')
    cfg
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /^(.* uptime is ).*\n/, '\1'
    comment cfg
  end

  cmd 'show transceiver' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
