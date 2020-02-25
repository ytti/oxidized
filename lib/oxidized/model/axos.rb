class AxOS < Oxidized::Model
  prompt /(\x1b\[\?7h)?([\w.@()-]+[#]\s?)$/
  comment '! '

  cmd 'show running-config | nomore' do |cfg|
    cfg.cut_head
  end

  cmd :all do |cfg|
    cfg.cut_tail
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
