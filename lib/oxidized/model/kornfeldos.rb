class KornfeldOS < Oxidized::Model
  using Refinements

  # For switches running Kornfeld OS
  #
  # Tested with : Kornfeld D1156 and Kornfeld D2132

  comment  '# '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both(2)
  end

  cmd 'show version | except REPOSITORY | except docker | except Uptime' do |cfg|
    comment cfg
  end

  cmd 'show platform firmware' do |cfg|
    comment cfg
  end

  cmd 'show running-configuration'

  cfg :ssh do
    username /^Login:/
    password /^Password:/
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
