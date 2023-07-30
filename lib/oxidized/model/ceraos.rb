class Ceraos < Oxidized::Model
  prompt /root\>/

  expect /(END)/ do |data, re|
    send 'q'
    data.sub re, ''
  end

  expect /^:/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd 'platform configuration configuration-file show'

  cmd 'platform software show versions all'

  cmd :all do |cfg|
    cfg.gsub! /\e.*/, ''
  end

  cfg :ssh do
    pre_logout 'quit'
  end
end
