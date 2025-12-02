class NXOS < Oxidized::Model
  using Refinements

  prompt /^(\r?[\w.@_()-]+\#\s?)$/
  comment '! '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp-server user (\S+) (\S+) auth (\S+)) (\S+) (priv) (\S+)/, '\\1 <secret hidden> '
    cfg.gsub! /^(snmp-server host.*? )\S+( udp-port \d+)?$/, '\\1<secret hidden>\\2'
    cfg.gsub! /^(snmp-server mib community-map) \S+ ?(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(password \d+) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(radius-server .*key(?: \d+)?) \S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server .*key(?: \d+)?) \S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.take_while { |line| not line.match(/uptime|bootflash:\s+\d+\skB|sysmgrcli_show_flash_size/i) }
    comment cfg.join + "\n"
  end

  cmd 'show inventory all' do |cfg|
    if cfg.include? "% Invalid parameter detected at '^' marker."
      # 'show inventory all' isn't supported on older versions (See Issue #3657)
      cfg = cmd 'show inventory'
    end
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^(show run.*)$/, '! \1'
    cfg.gsub! /^!Time:[^\n]*\n/, ''
    cfg.gsub! /^[\w.@_()-]+\#.*$/, ''
    cfg
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^login:/
    password /^Password:/
  end
end
