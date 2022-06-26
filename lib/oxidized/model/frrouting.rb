class FRRouting < Oxidized::Model
  prompt /^((\w*)@(.*)):/
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

    cfg += add_comment 'MOTD'
    cfg += cmd 'cat /etc/motd'

    cfg += add_comment 'PASSWD'
    cfg += cmd 'cat /etc/passwd'

    cfg += add_comment "VTYSH Running-Config"
    cfg += cmd 'vtysh -c "show running-config"'

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
