class Awplus < Oxidized::Model

  #Allied Telesis Alliedware Plus Model#

  prompt /^(\r?[\w.@:\/-]+[#>]\s?)$/
  comment  '! '

  #This shows the system information at the top and comments it out#
  cmd 'show system' do |cfg|
    cfg = cfg.each_line.to_a[0...-2]


   # Strip system (up)time/ram/free flash.
    cfg = cfg.reject { |line| line.match /System Status\s*.*/ }
    cfg = cfg.reject { |line| line.match /RAM\s*:.*/ }
    cfg = cfg.reject { |line| line.match /Uptime\s*:.*/ }
    cfg = cfg.reject { |line| line.match /Flash\s*:.*/ }
   #cfg = cfg.reject { |line| line.match /Current software\s*:.*/ }
   #cfg = cfg.reject { |line| line.match /Software version\s*:.*/ }
   #cfg = cfg.reject { |line| line.match /Build date\s*:.*/ }

    comment cfg.join
    end


  #Horrible way of adding a line to separate the above 'show sys' and the running-config
  #Note this line gets sent to the device. 
  cmd '!-----------------------------------------------------------------' do |cfg|
     cfg
  end


  #Actually get the running config#
  cmd 'show running-config' do |cfg|
    cfg
  end

  #Only configured for SSH. Needed to add 'enable' as Priv-Exec users don't get
  #put into "enable mode" by default on login.
  #Set term length to 0 so the entire config is output without intervention.
  #Finally, "terminal no length" is added to set the terminal length back to default.

  cfg :ssh do
    post_login 'enable'
    post_login 'terminal length 0'
    pre_logout 'terminal no length'
    pre_logout 'exit'
  end


end
