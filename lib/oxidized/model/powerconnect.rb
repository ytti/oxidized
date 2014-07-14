class PowerConnect < Oxidized::Model

  prompt /^([\w\s.@-]+[#>]\s?)$/ # allow spaces in hostname..dell does not limit it.. #

  comment  '! '

  expect /^\s--More--\s+.*$/ do |data, re|
     send ' '
     data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    cfg = cfg.each_line.take_while { |line| not line.match(/uptime/i) }
    comment cfg
  end

  cmd 'show running-config'

  cfg :telnet do
    username /^User( Name)?:/
    password /^\r?Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal datadump'
    post_login 'enable'
    pre_logout 'exit'
  end

end
