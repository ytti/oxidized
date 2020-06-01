class ZTEOLT < Oxidized::Model
  prompt /^([\w.@()-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version-running' do |cfg|
    comment cfg
  end

  cmd 'show patch-running' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^timestamp_write: .*\n/, ''
    cfg
  end

  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout do
       cmd 'disable'
       cmd 'exit'
    end
  end
end
