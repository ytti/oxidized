class Voss < Oxidized::Model
  # Avaya VSP Operating System Software(VOSS)
  # Created by danielcoxman@gmail.com
  # May 25, 2017
  # This was tested on vsp4k and vsp8k

  comment '# '

  prompt /^[^\s#>]+[#>]$/

  # needed for proper formatting after post_login
  cmd('') { |cfg| comment "#{cfg}\n" }
  
  # Get sys-info and remove information that changes such has temperature and power
  cmd 'show sys-info' do |cfg|
    cfg.gsub! /(^((.*)SysUpTime(.*))$)/, 'removed SysUpTime'
    cfg.gsub! /^((.*)Temperature Info \:(.*\r?\n){4})/, 'removed Temperature Info and 3 more lines'
    cfg.gsub! /(^((.*)AmbientTemperature(.*)\:(.*))$)/, 'removed AmbientTemperature'
    cfg.gsub! /(^((.*)Temperature(.*)\:(.*))$)/, 'removed Temperature'
    cfg.gsub! /(^((.*)Total Power Usage(.*)\:(.*))$)/, 'removed Total Power Usage'
    comment "#{cfg}\n"
  end

  # more the config rather than doing a show run
  cmd 'more config.cfg' do |cfg|
    cfg
    cfg.gsub! /^[^\s#>]+[#>]$/, ''
    cfg.gsub! /^more config.cfg/, '# more config.cfg'
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
