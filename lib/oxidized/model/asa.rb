class ASA < Oxidized::Model

  # Cisco ASA model #
  # Only SSH supported for the sake of security

  prompt /^\r*([\w.@()-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /enable password (\S+) (.*)/, 'enable password <secret hidden> \2'
    cfg.gsub! /username (\S+) password (\S+) (.*)/, 'username \1 password <secret hidden> \3'
    cfg
  end

  cmd 'show clock' do |cfg|
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^: [^\n]*\n/, ''
    cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cfg :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    post_login 'terminal pager 0'
    pre_logout 'exit'
  end

end
