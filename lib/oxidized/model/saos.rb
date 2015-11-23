class SAOS < Oxidized::Model

  # Ciena SAOS switch
  # used for 6.x devices
 
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'configuration show' do |cfg|
    cfg
  end

  cfg :telnet do
    username /login:/
    password /assword:/
  end
  cfg :telnet do
    post_login 'system shell session set more off'
    pre_logout 'exit'
  end
end