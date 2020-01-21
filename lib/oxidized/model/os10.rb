class OS10 < Oxidized::Model
  # Dell-OS10 model #

  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[2..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /(password )(\S+)/, '\1<secret hidden>'
    cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show inventory media' do |cfg|
    comment cfg
  end

  cmd 'show running-configuration' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
 end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
 end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
