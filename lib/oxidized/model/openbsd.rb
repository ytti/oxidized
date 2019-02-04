class Openbsd < Oxidized::Model
  # OpenBSD with custom promp, like user@hostname:~$
  # you can edit the one that your user uses, with root would be /root/.profile using the next PS1 def
  # export PS1="\033[32m\u@\h\033[00m:\033[36m\w\033[00m$ "

  prompt /^.+@.+\:.+\$/
  comment '# '

  # Add a comment between files/configs
  def add_comment(comment)
    "\n+++++++++++++++++++++++++++++++++++++++++ #{comment} ++++++++++++++++++++++++++++++++++++++++++++++\n"
  end

  def add_small_comment(comment)
    "\n=============== #{comment} ===============\n"
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # Issue the show commands
  pre do
    cfg = add_comment('HOSTNAME FILE')
    cfg += cmd('cat /etc/myname')

    cfg += add_comment('RESOLV.CONF FILE')
    cfg += cmd('cat /etc/resolv.conf')

    cfg += add_comment('NTP.CONF FILE')
    cfg += cmd('cat /etc/ntp.conf')

    cfg += add_comment('PF FILE')
    cfg += cmd('cat /etc/pf.conf')

    cfg += add_comment('HOSTS FILE')
    cfg += cmd('cat /etc/hosts')

    cfg += add_comment('INTERFACE FILES')
    cfg += cmd('tail -n +1 /etc/hostname.*')

    cfg += add_comment('SNMP FILE')
    cfg += cmd('cat /etc/snmpd.conf')

    cfg += add_comment('MOTD FILE')
    cfg += cmd('cat /etc/motd')

    cfg += add_comment('PASSWD FILE')
    cfg += cmd('cat /etc/passwd')

    cfg += add_small_comment('END')
    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
