class SNR < Oxidized::Model

  comment '!'

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[1..-1]
  end

  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

end
