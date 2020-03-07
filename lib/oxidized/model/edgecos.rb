class EdgeCOS < Oxidized::Model
  comment '! '

  cmd :secret do |cfg|
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[0..-2].join
  end

  cmd 'show running-config'

  cmd 'show system' do |cfg|
    cfg.gsub! /^.*\sUp Time\s*:.*\n/i, ''
    cfg.gsub! /^(.*\sTemperature \d*:).*\n/i, '\\1 <removed>'
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show watchdog' do |cfg|
    comment cfg
  end

  cmd 'show interfaces transceiver' do |cfg|
    cfg.gsub! /(\d\d)!/, '\\1 ' # alarm indicators of DDM thresholds
    cfg.gsub! /^(\s*Temperature\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*Vcc\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*Bias Current\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*TX Power\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*RX Power\s*:).*/, '\1 <hidden>'
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
