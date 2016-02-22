class EdgeSwitch < Oxidized::Model

# Ubiquiti EdgeSwitch #

  comment '!'

  prompt /[(]\w*\s\w*[)][\s#>]*[\s#>]/

  cmd 'show running-config' do |cfg|
    cfg.each_line.reject { |line| line.match /System Up Time.*/ or line.match /Current SNTP Synchronized Time.*/ }.join
  end

  cfg :telnet do
    username /Username:\s/
    password /^Password:\s/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end

end
