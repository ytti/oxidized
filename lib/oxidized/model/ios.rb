class IOS < Oxidized::Model

  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.sub! /^(ntp clock-period).*/, '! \1'
    cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
  end

end
