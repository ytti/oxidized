class FSOS < Oxidized::Model
  # Fiberstore / fs.com
  using Refinements
  comment '! '
  prompt /^([\w.@()-]+[#>]\s?)$/

  # Handle paging
  expect /^ --More--.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :secret do |cfg|
    cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(snmp-server community \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp-server host \S+( udp-port \d+)?( permit|deny \d+)?( informs?)?( traps?)?(( version v3 (priv|auth|noauth))|( version (v1|v2c))?)) +\S+( .*)?$*/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp-server user \S+ \S+ v3( priv (des|aes128|aes256|aes256-c))?( auth (md5|sha|sha256) \d+)) +\S+( .*)?$*/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*key \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    # Remove uptime so the result doesn't change every time
    cfg.gsub! /.*uptime is.*\n/, ''
    cfg.gsub! /.*System uptime.*\n/, ''
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    # Remove "Building configuration..." message
    cfg.gsub! /^Building configuration.*\n/, ''
    cfg.cut_head
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    post_login 'terminal length 0'
    post_login 'terminal width 512'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
