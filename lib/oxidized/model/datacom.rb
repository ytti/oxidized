class DataCom < Oxidized::Model
  comment '! '

  expect /^--More--\s+$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.cut_head.cut_both.cut_tail
  end

  cmd 'show firmware' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.cut_head
  end

  cfg :ssh do
    password /^Password:\s$/
    pre_logout 'exit'
  end

  cfg :telnet do
    username /login:\s$/
    password /^Password:\s$/
    pre_logout 'exit'
  end
end
