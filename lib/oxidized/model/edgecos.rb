class EdgeCOS < Oxidized::Model
  comment '! '

  cmd :secret do |cfg|
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].join
  end

  cmd 'show running-config'

  cmd 'show system' do |cfg|
    cfg.gsub! /^\s*System Up Time\s*:.*\n/i, ''
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show watchdog' do |cfg|
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
