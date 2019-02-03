class Cumulus < Oxidized::Model
  prompt /^((\w*)@(.*)):/
  comment '# '

  # add a comment in the final conf
  def add_comment(comment)
    "\n###### #{comment} ######\n"
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  # show the persistent configuration
  pre do
    # Set FRR or Quagga in config
    routing_daemon = vars(:cumulus_routing_daemon) ? vars(:cumulus_routing_daemon).downcase : 'quagga'
    routing_conf_file = routing_daemon == 'frr' ? 'frr.conf' : 'Quagga.conf'
    routing_daemon_shout = routing_daemon.upcase

    cfg = add_comment 'THE HOSTNAME'
    cfg += cmd 'cat /etc/hostname'

    cfg += add_comment 'THE HOSTS'
    cfg += cmd 'cat /etc/hosts'

    cfg += add_comment 'THE INTERFACES'
    cfg += cmd 'grep -r "" /etc/network/interface* | cut -d "/" -f 4-'

    cfg += add_comment 'RESOLV.CONF'
    cfg += cmd 'cat /etc/resolv.conf'

    cfg += add_comment 'NTP.CONF'
    cfg += cmd 'cat /etc/ntp.conf'

    cfg += add_comment 'IP Routes'
    cfg += cmd 'netstat -rn'

    cfg += add_comment 'SNMP settings'
    cfg += cmd 'cat /etc/snmp/snmpd.conf'

    cfg += add_comment "#{routing_daemon_shout} DAEMONS"
    cfg += cmd "cat /etc/#{routing_daemon}/daemons"

    cfg += add_comment "#{routing_daemon_shout} ZEBRA"
    cfg += cmd "cat /etc/#{routing_daemon}/zebra.conf"

    cfg += add_comment "#{routing_daemon_shout} BGP"
    cfg += cmd "cat /etc/#{routing_daemon}/bgpd.conf"

    cfg += add_comment "#{routing_daemon_shout} OSPF"
    cfg += cmd "cat /etc/#{routing_daemon}/ospfd.conf"

    cfg += add_comment "#{routing_daemon_shout} OSPF6"
    cfg += cmd "cat /etc/#{routing_daemon}/ospf6d.conf"

    cfg += add_comment "#{routing_daemon_shout} CONF"
    cfg += cmd "cat /etc/#{routing_daemon}/#{routing_conf_file}"

    cfg += add_comment 'MOTD'
    cfg += cmd 'cat /etc/motd'

    cfg += add_comment 'PASSWD'
    cfg += cmd 'cat /etc/passwd'

    cfg += add_comment 'SWITCHD'
    cfg += cmd 'cat /etc/cumulus/switchd.conf'

    cfg += add_comment 'PORTS'
    cfg += cmd 'cat /etc/cumulus/ports.conf'

    cfg += add_comment 'TRAFFIC'
    cfg += cmd 'cat /etc/cumulus/datapath/traffic.conf'

    cfg += add_comment 'ACL'
    cfg += cmd 'iptables -L -n'

    cfg += add_comment 'VERSION'
    cfg += cmd 'cat /etc/cumulus/etc.replace/os-release'

    cfg += add_comment 'License'
    cfg += cmd 'cl-license'

    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "sudo su -", /^\[sudo\] password/
        cmd @node.auth[:password]
      elsif vars(:enable)
        cmd "su -", /^Password:/
        cmd vars(:enable)
      end
    end

    pre_logout do
      cmd "exit" if vars(:enable)
    end
    pre_logout 'exit'
  end
end
