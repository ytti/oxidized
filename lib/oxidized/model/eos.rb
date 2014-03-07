class EOS < Oxidized::Model

  # Arista EOS model #
  # need to add telnet support here .. #

  prompt /^[^\(]+\([^\)]+\)#/

  comment  '! '

  cmd 'show inventory | no-more' do |cfg|
    comment cfg
  end

  cmd 'show running-config | no-more' do |cfg|
    cfg
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end

end
