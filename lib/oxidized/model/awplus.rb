class AWPlus < Oxidized::Model

#Allied Telesis Alliedware Plus Model#
#https://www.alliedtelesis.com/products/software/AlliedWare-Plus
  
  prompt /^(\r?[\w.@:\/-]+[#>]\s?)$/
  comment  '! '

#Avoids needing "term length 0" however may print other pager characters in config
#  expect /--More--/ do |data, re|
#    send ' '
#    data.sub re, ''
#  end

#Remove passwords from config file.
#Add vars "remove_secret: true" to global oxidized config file to enable. 

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username \S+ privilege \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(username \S+ password \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(username \S+ secret \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret) \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server key \d) (\S+)/, '\\1 <secret hidden>'
    cfg
  end

#Adds "Show system" output to start of config. 
   cmd 'Show System' do |cfg|
#Removes the following lines from "show system" in output file. This ensures oxidized diffs are meaningful. 
    cfg.gsub! /System Status\s*.*/, ''
    cfg.gsub! /RAM\s*:.*/, ''
    cfg.gsub! /Uptime\s*:.*/, ''
    cfg.gsub! /Flash\s*:.*/, ''
    cfg.gsub! /Current software\s*:.*/, ''
    cfg.gsub! /Software version\s*:.*/, ''
    cfg.gsub! /Build date\s*:.*/, ''
    cfg.gsub! /^$\n/, '' #Remove blank lines in show sys caused by removal of above output.
    comment cfg.insert(0,"--------------------------------------------------------------------------------! \n")
#	Unhash below to write a comment in the config file.
    cfg.insert(0,"Starting: Show system cmd \n")
    comment cfg
#	Unhash below to write a comment in the config file.
   cfg << "\n\nEnding: show system cmd"
    comment cfg << "\n--------------------------------------------------------------------------------! \n\n"
    end

#Actually get the devices running config#
  cmd 'show running-config' do |cfg|
    cfg
  end
  
#Config required for telnet to detect username prompt
  cfg :telnet do
    username /login:\s/
    end

#Main login config
    cfg :telnet, :ssh do
    post_login do
      if vars :enable
        send "enable\n"
        expect /^Password:\s/
        cmd vars(:enable) + "\r\n"
      else
        cmd 'enable' # Required for Priv-Exec users without enable PW to be put into "enable mode". 
      end
      cmd 'terminal length 0' #set so the entire config is output without intervention.
    end
    pre_logout do
      cmd 'terminal no length' #Sets term length back to default on exit. 
      send  "exit\r\n"
    end
  end  

end

