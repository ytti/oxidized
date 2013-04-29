class PowerConnect < Oxidized::Model

  prompt /^([\w\s.@-]+[#>]\s?)$/ # allow spaces in hostname..dell does not limit it.. #
 
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^User Name:/
    password /^\r?Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal datadump'
    pre_logout 'exit'
  end

end
