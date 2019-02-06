class NXOS < Oxidized::Model
  prompt /^(\r?[\w.@_()-]+[#]\s?)$/
  comment '! '

  def filter(cfg)
    cfg.gsub! /\r\n?/, "\n"
    cfg.gsub! prompt, ''
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp-server user (\S+) (\S+) auth (\S+)) (\S+) (priv) (\S+)/, '\\1 <configuration removed> '
    cfg.gsub! /^(username \S+ password \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(radius-server key).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = filter cfg
    cfg = cfg.each_line.take_while { |line| not line.match(/uptime/i) }
    comment cfg.join ""
  end

  cmd 'show inventory' do |cfg|
    cfg = filter cfg
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = filter cfg
    cfg.gsub! /^(show run.*)$/, '! \1'
    cfg.gsub! /^!Time:[^\n]*\n/, ''
    cfg.gsub! /^[\w.@_()-]+[#].*$/, ''
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
