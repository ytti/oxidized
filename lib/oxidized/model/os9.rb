# For switches running Dell EMC Networking OS9 #
class OS9 < Oxidized::Model
    # For switches running Dell EMC Networking OS9 #
    #
    # Tested with : Dell S4048F-ON
  
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
  
    cmd 'show running-config' do |cfg|
      cfg.each_line.to_a[3..-1].join
    end
  
    cfg :telnet do
      username /^Login:/
      password /^Password:/
    end
  
    cfg :telnet, :ssh do
      post_login 'terminal length 0'
      pre_logout 'exit'
    end
  end
  