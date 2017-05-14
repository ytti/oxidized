class Voss < Oxidized::Model
  # Avaya VSP Operating System Software(VOSS)
  # Created by danielcoxman@gmail.com
  # May 9, 2017
  # This was tested on vsp4k and vsp8k

  comment '# '

  prompt /^[^\s#>]+[#>]$/

  cmd 'show sys-info' do |cfg|
    comment cfg
  end

  # more the config rather than doing a show run
  cmd 'more config.cfg' do |cfg|
    cfg
    cfg.gsub! /^[^\s#>]+[#>]$/, ''
    cfg.gsub! /^more config.cfg/, ''
  end

  cfg :telnet do
    username /Login: $/
    password /Password: $/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
    post_login 'enable'
    post_login 'terminal more disable'
  end

end
