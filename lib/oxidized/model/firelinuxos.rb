class FireLinuxOS < Oxidized::Model
  using Refinements

  # Fire Linux OS is what the new FTD (FirePOWER) series devices from Cisco run. At the backend, it's mostly identical to ASA's.

  prompt /^[#>]\(?.+\)? ?$/
  comment '! '

  expect /^Syntax error: .*\n.*$/ do |data, re|
    # The firepower does not remove the entered command, so
    # Send CTRL-U and \n for a fresh prompt
    send "\x15\n"
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    # Ged rid of ANSI escape codes
    cfg.gsub! /\e\[[0-?]*[ -\/]*[@-~]\r?/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /enable password (\S+) (.*)/, 'enable password <secret hidden> \2'
    cfg.gsub! /username (\S+) password (\S+) (.*)/, 'username \1 password <secret hidden> \3'
    cfg.gsub! /(ikev[12] ((remote|local)-authentication )?pre-shared-key) (\S+)/, '\1 <secret hidden>'
    cfg.gsub! /^(aaa-server TACACS\+? \(\S+\) host.*\n\skey) \S+$/mi, '\1 <secret hidden>'
    cfg.gsub! /ldap-login-password (\S+)/, 'ldap-login-password <secret hidden>'
    cfg.gsub! /^snmp-server host (.*) community (\S+)/, 'snmp-server host \1 community <secret hidden>'
    cfg
  end

  cmd 'show version system' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /(\s+up\s+\d+\s+)|(.*days.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show running-config all' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^: [^\n]*\n/, ''
    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
