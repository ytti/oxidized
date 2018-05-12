class HPEBladeSystem < Oxidized::Model
  # HPE Onboard Administrator

  prompt /.*> /
  comment '# '

  # expect /^\s*--More--\s+.*$/ do |data, re|
  #   send ' '
  #   data.sub re, ''
  # end

  cmd :all do |cfg|
    cfg = cfg.delete("\r").each_line.to_a[0..-1].map { |line| line.rstrip }.join("\n") + "\n"
    cfg.cut_tail
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(SET SNMP COMMUNITY (READ|WRITE)).*/, '\\1 <configuration removed>'
    cfg
  end

  cmd 'show oa info' do |cfg|
    comment cfg
  end

  cmd 'show oa network' do |cfg|
    comment cfg
  end

  cmd 'show oa certificate' do |cfg|
    comment cfg
  end

  cmd 'show sshfingerprint' do |cfg|
    comment cfg
  end

  cmd 'show fru' do |cfg|
    comment cfg
  end

  cmd 'show network' do |cfg|
    cfg.gsub! /Last Update:.*$/i, ''
    comment cfg
  end

  cmd 'show vlan' do |cfg|
    comment cfg
  end

  cmd 'show rack name' do |cfg|
    comment cfg
  end

  cmd 'show server list' do |cfg|
    comment cfg
  end

  cmd 'show server names' do |cfg|
    comment cfg
  end

  cmd 'show server port map all' do |cfg|
    comment cfg
  end

  cmd 'show server info all' do |cfg|
    comment cfg
  end

  cmd 'show config' do |cfg|
    cfg.gsub! /^#(Generated on:) .*$/, '\\1 <removed>'
    cfg.gsub /^\s+/, ''
  end

  cfg :telnet do
    username /\slogin:/
    password /^Password: /
  end

  cfg :telnet, :ssh do
    post_login "set script mode on"
    pre_logout "exit"
  end
end
