class Eltex < Oxidized::Model
  # Tested with MES2324FB Version: 4.0.7.1 Build: 37 (master)

  prompt /^\s?[\w.@\(\)-]+[#>]\s?$/
  comment '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^((tacacs|radius) server [^\n]+\n(\s+[^\n]+\n)*\s+key) [^\n]+$/m, '\1 <secret hidden>'
    cfg.gsub! /username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^username \S+ password \d \S+/, '<secret hidden>'
    cfg.gsub! /^enable password \d \S+/, '<secret hidden>'
    cfg.gsub! /wpa-psk ascii \d \S+/, '<secret hidden>'
    cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :telnet do
    username /^(User Name):/
    password /^Password:/
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
    post_login 'terminal datadump'
    pre_logout 'disable'
    pre_logout 'exit'
  end
end
