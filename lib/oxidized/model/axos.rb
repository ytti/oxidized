class AXOS < Oxidized::Model
  prompt /([\w.@()-]+[#]\s?)$/
  comment '! '
  cmd 'show running-config | nomore' do |cfg|
    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
