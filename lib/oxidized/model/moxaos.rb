class MoxaOS < Oxidized::Model
  using Refinements

  prompt /(?:^|\e\[[\d;?]*[A-Za-z])([\w.@()-]+[#>]\s?)$/

  comment '! '

  expect /--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  # Hide sensitive information before storing the configuration
  cmd :secret do |cfg|
    # local user password hashes
    # e.g. "username admin password 810448e...d04180 privilege 1"
    cfg.gsub! /^(username\s+\S+\s+password)\s+\S+/, '\1 <secret hidden>'

    # SNMP read/write community strings
    # e.g. "snmp-server community public ro" / "... private rw"
    cfg.gsub! /^(snmp-server community\s+\S+)\s+(ro|rw)/, '<secret hidden> \2'

    # RADIUS / TACACS+ / MAB shared keys
    # e.g. "authentication tacacs+ login primary shared-key moxa"
    cfg.gsub! /^(.*shared-key)\s+\S+/, '\1 <secret hidden>'

    # Config file encryption password
    # e.g. "cfg-encrypt 12345"
    cfg.gsub! /^(cfg-encrypt)\s+\S+/, '\1 <secret hidden>'

    # SMTP/email-warning account credentials
    cfg.gsub! /^(email-warning smtp account\s+\S+)\s+\S+/, '\1 <secret hidden>'

    # dot1x local user passwords
    cfg.gsub! /^(authentication local dot1x username\s+\S+\s+password)\s+\S+/, '\1 <secret hidden>'

    cfg
  end

  cmd 'show system' do |cfg|
    cfg.gsub! /^[ \t]*(?:System Uptime|Memory Utilization|Power Consumption)[ \t]*:.*\n?/, ''
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Building configuration.*\n?/, ''
    cfg
  end

  cfg :telnet do
    username /^(Login|Username):/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
