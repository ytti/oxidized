class Openbsd < Oxidized::Model

  # OpenBSD with custom promp, like user@hostname:~$
  # you can edit the one that your user uses, with root would be /root/.profile using the next PS1 def
  # export PS1="\033[32m\u@\h\033[00m:\033[36m\w\033[00m$ "
  
  prompt /^.+@.+\:.+\$/
  comment '# '
  
  # Add a comment between files/configs
  def add_comment comment
    "\n+++++++++++++++++++++++++++++++++++++++++ #{comment} ++++++++++++++++++++++++++++++++++++++++++++++\n"
  end

  def add_small_comment comment
    "\n=============== #{comment} ===============\n"
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  # Issue the show commands
  pre do
    cfg = add_comment('HOSTNAME FILE')
    cfg = cfg + cmd('cat /etc/myname')
  
    cfg = cfg + add_comment('HOSTS FILE')
    cfg = cfg + cmd('cat /etc/hosts')
  
    cfg = cfg + add_comment('INTERFACE FILES')
    cfg = cfg + cmd('tail +n 1 /etc/hostname.*')
  
    cfg = cfg + add_comment('RESOLV.CONF FILE')
    cfg = cfg + cmd('cat /etc/resolv.conf')
  
    cfg = cfg + add_comment('NTP.CONF FILE')
    cfg = cfg + cmd('cat /etc/ntp.conf')
  
    cfg = cfg + add_comment('IP ROUTES PER ROUTING DOMAIN')
    cfg = cfg + add_small_comment('Routing Domain 0')
    cfg = cfg + cmd('route -T0 exec netstat -rn')
    cfg = cfg + add_small_comment('Routing Domain 1')
    cfg = cfg + cmd('route -T1 exec netstat -rn')
    cfg = cfg + add_small_comment('Routing Domain 2')
    cfg = cfg + cmd('route -T2 exec netstat -rn')
    cfg = cfg + add_small_comment('Routing Domain 3')
    cfg = cfg + cmd('route -T3 exec netstat -rn')
    cfg = cfg + add_small_comment('Routing Domain 4')
    cfg = cfg + cmd('route -T4 exec netstat -rn')
    cfg = cfg + add_small_comment('Routing Domain 5')
    cfg = cfg + cmd('route -T5 exec netstat -rn')
  
    cfg = cfg + add_comment('SNMP FILE')
    cfg = cfg + cmd('cat /etc/snmpd.conf')

    cfg = cfg + add_comment('PF FILE')
    cfg = cfg + cmd('cat /etc/pf.conf')

    cfg = cfg + add_comment('MOTD FILE')
    cfg = cfg + cmd('cat /etc/motd')

    cfg = cfg + add_comment('PASSWD FILE')
    cfg = cfg + cmd('cat /etc/passwd')

  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end

end
