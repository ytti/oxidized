class Procurve < Oxidized::Model
  # some models start lines with \r
  # previous command is repeated followed by "\eE", which sometimes ends up on last line
  prompt /^\r?([\w.-]+# )$/

  comment '! '

  # replace next line control sequence with a new line
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # replace all used vt100 control sequences
  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  expect /Press any key to continue(\e\[\??\d+(;\d+)*[A-Za-z])*$/ do
    send ' '
    ""
  end

  expect /Enter switch number/ do
    send "\n"
    ""
  end

  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^\r/, ''
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp-server host).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(radius-server host).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(radius-server key).*/, '\\1 <configuration removed>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show modules' do |cfg|
    comment cfg
  end

  cmd 'show system power-supply' do |cfg|
    comment cfg
  end

  cmd 'show interfaces transceiver' do |cfg|
    comment cfg
  end

  cmd 'show flash' do |cfg|
    comment cfg
  end

  # not supported on all models
  cmd 'show system-information' do |cfg|
    cfg = cfg.split("\n")[0..-8].join("\n")
    comment cfg
  end

  # not supported on all models
  cmd 'show system information' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /(.*CPU.*)|(.*Up Time.*)|(.*Total.*)|(.*Free.*)|(.*Lowest.*)|(.*Missed.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'show running-config'

  cfg :telnet do
    username /Username:/
    password /Password:/
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'no page'
    pre_logout "logout\ny\nn"
  end

  cfg :ssh do
    pty_options({ chars_wide: 1000 })
  end
end
