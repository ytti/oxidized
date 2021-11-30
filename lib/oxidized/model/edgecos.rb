class EdgeCOS < Oxidized::Model
  comment '! '

  # Handle pager for ES3526XA-V2
  expect /^---More---.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :secret do |cfg|
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  cmd :all do |cfg|
    # Do not show errors for commands that are not supported on some devices
    cfg.gsub! /^(% Invalid input detected at '\^' marker\.|^\s+\^)$/, ''
    # Handle pager for ES3526XA-V2
    cfg.gsub! /^([\b]{10}\s{10}[\b]{10})/, ''
    cfg.cut_both
  end

  cmd 'show running-config' do |cfg|
    # Remove "building running-config, please wait..." message
    cfg.cut_head
  end

  cmd 'show system' do |cfg|
    cfg.gsub! /^.*\sUp Time\s*:.*\n/i, ''
    cfg.gsub! /^(.*\sTemperature \d*:).*\n/i, '\\1 <removed>'
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show watchdog' do |cfg|
    comment cfg
  end

  cmd 'show interfaces transceiver' do |cfg|
    cfg.gsub! /(\d\d)!/, '\\1 ' # alarm indicators of DDM thresholds
    cfg.gsub! /^(\s*Temperature\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*Vcc\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*Bias Current\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*TX Power\s*:).*/, '\1 <hidden>'
    cfg.gsub! /^(\s*RX Power\s*:).*/, '\1 <hidden>'
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 300'
    pre_logout 'exit'
  end
end
