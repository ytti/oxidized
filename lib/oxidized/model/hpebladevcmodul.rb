class HPEBladeVCModul < Oxidized::Model
  # HPE Virtual Connect Module
  prompt /^->/ 
  comment '### '
  cmd :all do |cfg|
    cfg.cut_head.cut_tail
  end
  cmd 'show network' do |cfg|
    comment cfg
  end
  cmd 'show server' do |cfg|
    comment cfg
  end
  cmd 'show config'
  cfg :telnet do
    username /\slogin:/ 
    password /^Password: / 
  end
  cfg :ssh do
    pre_logout "exit"
  end
end
