class LinksysSRW < Oxidized::Model
  using Refinements

  comment '! '

  prompt /^([\r\w.@-]+[#>]\s?)$/

  # Graphical login screen
  # Just login to get to Main Menu
  expect /Login Screen/ do
    logger.debug "#{self.class.name}: Login Screen"
    # This is to ensure the whole thing have rendered before we send stuff
    sleep 0.2
    send 0x18.chr # CAN Cancel
    send @node.auth[:username]
    send "\t"
    send @node.auth[:password]
    send "\r"
    ''
  end

  # Main menu, escape into Pre-cli-shell
  expect /Switch Main Menu/ do
    logger.debug "#{self.class.name}: Switch menu"
    send 0x1a.chr # SUB Substitite ^z
    ''
  end

  # Pre-cli-shell, start lcli which is ios-ish
  expect />/ do
    logger.debug "#{self.class.name}: >"
    send "lcli\r"
    ''
  end

  cmd :all do |cfg|
    # Remove \r from first response row
    cfg.gsub! /^\r/, ''
    cfg.cut_tail + "\n"
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
  end

  cmd 'show startup-config' do |cfg|
    # Repair some linewraps which terminal datadump doesn't take care of
    # and there's no terminal width either.
    cfg.gsub! /(lldpPortConfigT)\n(LVsTxEnable)/, '\\1\\2'
    cfg.gsub! /(lldpPortConfigTL)\n(VsTxEnable)/, '\\1\\2'
    # And comment out the echo of the command
    "#{comment cfg.lines.first}#{cfg.cut_head}"
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    cfg.gsub! /(System Up Time \(days,hour:min:sec\):\s+).*/, '\\1 <uptime removed>'
    comment cfg
  end

  cfg :telnet, :ssh do
    # Some pre-cli-shell just expects a username, who its going to log in.
    username /^User Name:/
    password /Password:/
    post_login 'terminal datadump'
    pre_logout 'exit'
    pre_logout 'logout'
  end
end
