class Coriant8800 < Oxidized::Model

  comment '# '
  
  prompt /^[^\s#]+#\s/

  cmd 'show node extensive' do |cfg|
    comment cfg
  end

  cmd 'show run' do |cfg|
    cfg
  end

  cfg :telnet, :ssh do
    username /^Login:\s$/
    password /^Password:\s$/
    pre_logout 'exit'
    post_login 'enable config terminal length 0'
  end

end
