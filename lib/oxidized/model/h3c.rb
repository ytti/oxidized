class H3C < Oxidized::Model
  using Refinements

  # H3C

  prompt /^.*([<\[][\w.-]+[>\]])$/
  comment '# '

  cmd :secret do |cfg|
    cfg.gsub! /(pin verify (?:auto|)).*/, '\\1 <PIN hidden>'
    cfg.gsub! /(%\^%#.*%\^%#)/, '<secret hidden>'
    cfg
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cfg :telnet do
    username /^Username:$/
    password /^Password:$/
  end

  cfg :telnet, :ssh do
    post_login 'screen-length disable'
    pre_logout 'quit'
  end

  cmd 'display version' do |cfg|
    cfg = cfg.each_line.reject { |l| l.match /uptime/ }.join
    cfg = cfg.each_line.reject { |l| l.match /Uptime is/ }.join
    comment cfg
  end

  cmd 'display device' do |cfg|
    comment cfg
  end

  cmd 'display current-configuration' do |cfg|
    cfg
  end
end
