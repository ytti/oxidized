class ZhoneOLT < Oxidized::Model
  # Zhone OLT/MetroE/DSL devices (ONT uses a completely different CLI)

  # the prompt can be anything on zhone, but it defaults to 'zXX>' and we
  # always use hostname>
  prompt /^(\r*[\w.@():-]+[>]\s?)$/
  comment '# '

  cmd :secret do |cfg|
    cfg.gsub! /^(set configsyncpasswd = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set user-pass = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set auth-key = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set priv-key = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set ftp-password = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set community-name = ) \S+/, '\\1 <removed>'
    cfg.gsub! /^(set communityname = ) \S+/, '\\1 <removed>'
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  cmd 'swversion' do |cfg|
    comment cfg
  end

  cmd 'slots' do |cfg|
    comment cfg
  end

  cmd 'eeshow card' do |cfg|
    comment cfg
  end

  cmd 'ethrpshow' do |cfg|
    cfg = cfg.each_line.select { |line| line.match /Vendor (Name|OUI|Part|Revision)|Serial Number|Manufacturing Date/ }.join
    comment cfg
  end

  cmd 'dump console' do |cfg|
    cfg.each_line.reject { |line| line.match /To Abort the operation enter Ctrl-C/ }.join
  end

  # zhone technically supports ssh, but it locks up a ton.  Especially when
  # showing large amounts of output, like "dump console"
  cfg :telnet do
    username /\r*login:/
    password /\r*password:/
    pre_logout 'logout'
  end
end
