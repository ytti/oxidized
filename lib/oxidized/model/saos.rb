class SAOS < Oxidized::Model
  # Ciena SAOS switch
  # used for 6.x devices

  comment  '! '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'configuration show' do |cfg|
    cfg.gsub! /^! Created: [^\n]*\n/, ''
    cfg.gsub! /^! On terminal: [^\n]*\n/, ''
    cfg
  end

  cfg :telnet do
    username /login:/
    password /assword:/
  end

  cfg :telnet, :ssh do
    post_login 'system shell set more off'
    post_login 'system shell session set more off'
    pre_logout 'exit'
  end
end
