class TNSR < Oxidized::Model
  #tnsr from NetGate

  prompt /\w+#/
  comment "! "

  expect /^--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
   cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /(\s+<user-password>).+?(<\/user-password>)/, '\\1<password hidden>\\2'
    cfg.gsub! /(\s+<psk>).+?(<\/psk>)/, '\\1<psk hidden>\\2'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg
  end

  cmd 'show configuration running cli' do |cfg|
    cfg.insert(0,"\n-------- CLI Config Begin -------- \n")
    cfg
    cfg << "\n-------- CLI Config End -------- \n"
  end

  cmd 'show configuration running' do |cfg|
    cfg.insert(0,"\n-------- XML Config Begin -------- \n")
    cfg
    cfg << "\n-------- XML Config End -------- \n"
  end

  cfg :ssh do
    pre_logout 'exit'
  end
