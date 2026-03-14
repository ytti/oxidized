class KornfeldOS < Oxidized::Model
  using Refinements

  # For switches running Kornfeld OS
  #
  # Tested with : Kornfeld D1156 and Kornfeld D2132

  comment  '# '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[2..-2].join
  end

  cmd 'show version | except REPOSITORY | except docker | except Uptime' do |cfg|
    comment cfg
  end

  cmd 'show platform firmware' do |cfg|
    comment cfg
  end

  cmd 'show running-configuration' do |cfg|
    cfg.each_line.to_a[0..-1].join
  end

  cfg :ssh do
    username /^Login:/
    password /^Password:/
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
