class ZyNOS < Oxidized::Model
  using Refinements

  prompt /^([\w.@()-<]+[#>]\s?)$/
  # if there is something you can not identify after prompt, uncomment next line and comment previous line
  # prompt /^([\w.@()-<]+[#>]\s?).*$/

  comment '! '

  # Used in Zyxel DSLAMs, such as SAM1316. Uncomment next line to enable ftp.
  # cmd 'config-0'

  # replace next line control sequence with a new line
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # replace all used vt100 control sequences
  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  # ignore copyright motd
  expect /^(Copyright .*)\n^([\w.@()-<]+[#>]\s?)$/ do
    send '\n'
    ""
  end

  cmd :all do |cfg|
    cfg = cfg.gsub /^\r/, ''
    # Additional filtering for elder switches sending vt100 control chars via telnet
    cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
    cfg
  end

  # remove snmp community, username, password and admin-password
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server get-community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server set-community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(logins username) \S+(.*) (password) \S+(.*)/, '\\1 <secret hidden> \\2 \\3 <secret hidden> \\4'
    cfg.gsub! /^(admin-password) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(password) \S+(.*) (privilege \S+)/, '\\1 <secret hidden> \\2 \\3'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system-information' do |cfg|
    cfg.gsub! /^([Ss]ystem up [Tt]ime\s*:)(.*)/, '\\1 <time removed>'
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.split("\n")[4..-2].join("\n")
    cfg
  end

  cfg :telnet do
    username /^User name:/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
  end
end
