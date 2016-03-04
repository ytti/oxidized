class EdgeSwitch < Oxidized::Model

# Ubiquiti EdgeSwitch #

  comment '!'

  prompt /\(.*\)\s[#>]/

  cmd 'show running-config' do |cfg|
    cfg.each_line.to_a[2..-2].reject { |line| line.match /System Up Time.*/ or line.match /Current SNTP Synchronized Time.*/ }.join
  end

  cfg :telnet do
    username /Username:\s/
    password /^Password:\s/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    post_login 'terminal length 0'
    pre_logout 'quit'
  end

end
