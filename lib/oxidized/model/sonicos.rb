class SonicOS < Oxidized::Model

  prompt /^\w+@\w+[>]\(?.+\)?\s?/
  comment  '! '

  expect /\-\-MORE\-\-/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.select { |line| not line.match /system-time/ }
    cfg = cfg.each_line.select { |line| not line.match /(\s+up\s+\d+\s+)|(.*Days.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'show current-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^: [^\n]*\n/, ''
    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end
