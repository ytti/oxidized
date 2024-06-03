class OS6 < Oxidized::Model
  using Refinements

  # For switches running Dell EMC Networking OS6 #
  #
  # Tested with : Dell PowerSwitch N2048

  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.each_line.to_a[2..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /(password )(\S+)/, '\1<secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show interfaces transceiver properties' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.each_line.to_a[3..-1].join
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
