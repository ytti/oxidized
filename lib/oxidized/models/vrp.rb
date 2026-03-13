class VRP < Oxidized::Model
  using Refinements

  # Huawei VRP

  prompt /^.*(<[\w.-]+>)$/
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
    post_login 'screen-length 0 temporary'
    pre_logout 'quit'
  end

  cmd 'display version' do |cfg|
    cfg = cfg.each_line.reject do |l|
      l.match /uptime|^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/
    end.join
    comment cfg
  end

  cmd 'display device' do |cfg|
    cfg = cfg.each_line.reject { |l| l.match /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/ }.join
    comment cfg
  end

  cmd 'display current-configuration all' do |cfg|
    cfg = cfg.each_line.reject { |l| l.match /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d(\.\d\d\d)? ?(\+\d\d:\d\d)?$/ }.join
    cfg
  end
end
