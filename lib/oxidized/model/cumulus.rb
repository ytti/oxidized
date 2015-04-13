class Cumulus < Oxidized::Model
  
  prompt /^((\w*)@(.*)([>#]\s)+)$/
  comment  '# '
  
  
  #add a comment in the final conf
  def add_comment comment
    "\n###### #{comment} ######\n" 
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end
  
  #show the persistent configuration
  pre do
    cfg = add_comment 'THE HOSTNAME'
    cfg += cmd 'cat /etc/hostname'
    
    cfg += add_comment 'THE HOSTS'
    cfg += cmd 'cat /etc/hosts'
    
    cfg += add_comment 'THE INTERFACES'
    cfg += cmd 'cat /etc/network/interfaces'
    
    cfg += add_comment 'RESOLV.CONF'
    cfg += cmd 'cat /etc/resolv.conf'
    
    cfg += add_comment 'NTP.CONF'
    cfg += cmd 'cat /etc/ntp.conf'
    
    cfg += add_comment 'QUAGGA DAEMONS'
    cfg += cmd 'cat /etc/quagga/daemons'
    
    cfg += add_comment 'QUAGGA ZEBRA'
    cfg += cmd 'cat /etc/quagga/zebra.conf'
    
    cfg += add_comment 'QUAGGA BGP'
    cfg += cmd 'cat /etc/quagga/bgpd.conf'
    
    cfg += add_comment 'QUAGGA OSPF'
    cfg += cmd 'cat /etc/quagga/ospfd.conf'
    
    cfg += add_comment 'QUAGGA OSPF6'
    cfg += cmd 'cat /etc/quagga/ospf6d.conf'
    
    cfg += add_comment 'MOTD'
    cfg += cmd 'cat /etc/motd'
    
    cfg += add_comment 'PASSWD'
    cfg += cmd 'cat /etc/passwd'
    
    cfg += add_comment ' SWITCHD'
    cfg += cmd 'cat /etc/cumulus/switchd.conf'
    
    cfg += add_comment 'ACL'
    cfg += cmd 'iptables -L'
    
    cfg += add_comment 'VERSION'
    cfg += cmd 'cat /etc/cumulus/etc.replace/os-release'
    
  end
  

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
 

end