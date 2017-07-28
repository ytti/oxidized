class FireLinuxOS < Oxidized::Model

  prompt /^[#>]\(?.+\)?\s?/
  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[1..-2].join
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

  # check for multiple contexts
  cmd 'show mode' do |cfg|
    @is_multiple_context = cfg.include? 'multiple'
  end

  cmd 'show version system' do |cfg|
    cfg = cfg.each_line.select { |line| not line.match /(\s+up\s+\d+\s+)|(.*days.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show running-config all' do |cfg|
    cfg = cfg.each_line.to_a[3..-1]
    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end
