class IOS < Oxidized::Model

  comment  '! '

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-2].join
    cfg.sub! /^(ntp clock-period).*/, '! \1'
    cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg.each_line.to_a[1..-2].join
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
