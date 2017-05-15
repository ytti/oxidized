class Voss < Oxidized::Model
  # Avaya VSP Operating System Software(VOSS)
  # Created by danielcoxman@gmail.com
  # May 15, 2017
  # This was tested on vsp4k and vsp8k

  comment '# '

  prompt /^[^\s#>]+[#>]$/

  # needed for proper formatting after post_login
  cmd('') { |cfg| comment "#{cfg}\n" }
  # get some general information about switch
  cmd('show sys-info card') { |cfg| comment "#{cfg}\n" }
  cmd('show sys-info fan') { |cfg| comment "#{cfg}\n" }
  cmd('show sys-info power') { |cfg| comment "#{cfg}\n" }

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
    post_login do
      send "enable\n"
      send "terminal more disable\n"
      # Backup the config via tftp to a tftpserver of your choice
      #send "copy config.cfg x.x.x.x:" + node.name + ".cfg\n"
    end
  end

end
