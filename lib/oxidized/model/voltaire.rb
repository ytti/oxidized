class VOLTAIRE < Oxidized::Model
  prompt /([\w.@()-\[:\s\]]+[#>]\s|(One or more tests have failed.*))$/
  comment '## '

  # Pager Handling
  expect /.+lines\s\d+-\d+([\s]|\/\d+\s\(END\)\s).+$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.gsub! /\[\?1h=\r/, '' # Pager Handling
    cfg.gsub! /\r\[K/, '' # Pager Handling
    cfg.gsub! /\s/, '' # Linebreak Handling
    cfg.gsub! /^CPU load averages:\s.+/, '' # Omit constantly changing CPU info
    cfg.gsub! /^System memory:\s.+/, '' # Omit constantly changing memory info
    cfg.gsub! /^Uptime:\s.+/, '' # Omit constantly changing uptime info
    cfg.gsub! /.+Generated at\s\d+.+/, '' # Omit constantly changing generation time info
    cfg.lines.to_a[2..-3].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /(snmp-server community).*/, '   <snmp-server community configuration removed>'
    cfg.gsub! /username (\S+) password (\d+) (\S+).*/, '<secret hidden>'
    cfg
  end

  cmd 'version show' do |cfg|
    comment cfg
  end

  cmd 'firmware-version show' do |cfg|
    comment cfg
  end

  cmd 'remote show' do |cfg|
    cfg
  end

  cmd 'sm-info show' do |cfg|
    cfg
  end

  cmd ' show' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login "no\n"
    password /^Password:\s*/
    pre_logout 'exit'
  end
end
