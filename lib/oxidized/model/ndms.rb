class NDMS < Oxidized::Model
  # Pull config from Zyxel Keenetic devices from version NDMS >= 2.0

  comment  '! '

  prompt /^([\w.@()-]+[#>]\s?)/m

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.to_a[1..-3].join
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.cut_both.each_line.reject { |line| line.match /(clock date|checksum)/ }.join
    cfg
  end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
    pre_logout 'exit'
  end
end
