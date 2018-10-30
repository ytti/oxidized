class Firebrick < Oxidized::Model
  # Firebrick #

  prompt /.*[>]/

  cmd 'show status' do |cfg|
    cfg.gsub! /Status/, ''
    cfg.gsub! /------/, ''
    cfg.gsub! /Uptime.*/, ''
    cfg.gsub! /Current time.*/, ''
    cfg.gsub! /RAM.*/, ''
    cfg.gsub! /Warranty.*/, ''

    comment cfg
  end

  cmd 'show configuration' do |cfg|
    cfg
  end

  cfg :telnet do
    username /User(name)?:\s?/
    password /^Password:\s?/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
