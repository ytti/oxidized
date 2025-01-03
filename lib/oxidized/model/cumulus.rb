class Cumulus < Oxidized::Model
  using Refinements

  # Remove ANSI escape codes
  expect /\e\[[0-?]*[ -\/]*[@-~]\r?/ do |data, re|
    data.gsub re, ''
  end

  # The prompt contains ANSI escape codes, which have already been removed
  # from the expect call above
  # ^                 : match begin of line, to have the most specific prompt
  # [\w.-]+@[\w.-]+   : user@hostname
  # (:mgmt)?          : optional when logged in out of band
  # :~[#$] $          : end of prompt, containing the linux path,
  #                     which is always "~" in our context
  prompt /^[\w.-]+@[\w.-]+(:mgmt)?:~[#$] $/
  comment '# '

  # add a comment in the final conf
  def add_comment(comment)
    "\n###### #{comment} ######\n"
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /password (\S+)/, 'password <hidden>'
    cfg
  end

  # show the persistent configuration
  pre do
    use_nclu = vars(:cumulus_use_nclu) || false
    use_nvue = vars(:cumulus_use_nvue) || false

    if use_nclu
      cfg = cmd 'net show configuration commands'
    elsif use_nvue
      cfg = cmd 'nv config show --color off'
    else
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
      # in some configurations, ports.conf has no trailing Line Feed,
      # which breaks the prompt, so we add one
      cfg += cmd "cat /etc/cumulus/ports.conf; echo"

      cfg += add_comment 'TRAFFIC'
      cfg += cmd 'cat /etc/cumulus/datapath/traffic.conf'

      cfg += add_comment 'ACL'
      cfg += cmd 'cat /etc/cumulus/acl/policy.conf'

      cfg += add_comment 'DHCP-RELAY'
      cfg += cmd 'cat /etc/default/isc-dhcp-relay'

      cfg += add_comment 'VERSION'
      cfg += cmd 'cat /etc/cumulus/etc.replace/os-release'

      cfg += add_comment 'License'
      cfg += cmd 'cl-license'
    end

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
