class LinuxGeneric < Oxidized::Model
  prompt /^(\w.*|\W.*)(:|#) /
  comment '# '

  # add a comment in the final conf
  def add_comment(comment)
    "\n###### #{comment} ######\n"
  end

  cmd :all do |cfg|
    cfg.gsub! /^(default (\S+).* (expires) ).*/, '\\1 <redacted>'
    cfg.cut_both
  end

  # show the persistent configuration
  pre do
    cfg = add_comment 'THE HOSTNAME'
    cfg += cmd 'cat /etc/hostname'

    cfg += add_comment 'THE HOSTS'
    cfg += cmd 'cat /etc/hosts'

    cfg += add_comment 'THE INTERFACES'
    cfg += cmd 'ip link'

    cfg += add_comment 'RESOLV.CONF'
    cfg += cmd 'cat /etc/resolv.conf'

    cfg += add_comment 'IP Routes'
    cfg += cmd 'ip route'

    cfg += add_comment 'IPv6 Routes'
    cfg += cmd 'ip -6 route'

    cfg += add_comment 'MOTD'
    cfg += cmd 'cat /etc/motd'

    cfg += add_comment 'PASSWD'
    cfg += cmd 'cat /etc/passwd'

    cfg += add_comment 'GROUP'
    cfg += cmd 'cat /etc/group'

    cfg += add_comment 'nsswitch.conf'
    cfg += cmd 'cat /etc/nsswitch.conf'

    cfg += add_comment 'VERSION'
    cfg += cmd 'cat /etc/issue'

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
