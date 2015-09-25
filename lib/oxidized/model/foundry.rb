# Oxidized model for Foundry/Brocade switch models that run IronWare
# but require carriage return instead of newline on enable command
# and require different filters for temperature/uptime lines
class Foundry < Oxidized::Model

  prompt /^.*(telnet|ssh)\@.+[>#]\s?$/i
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[3..-1].join unless arr.length <= 3
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /(^((.*)[Ss]ystem uptime(.*))$)/, '' #remove unwanted line system uptime

    comment cfg
  end

  cmd 'show chassis' do |cfg|
    cfg.encode!("UTF-8", :invalid => :replace) #sometimes ironware returns broken encoding
    cfg.gsub! /\d{2}\.\d deg-C$/, 'XX.X deg-C'

    comment cfg
  end

  cmd 'show flash' do |cfg|
    comment cfg
  end

  cmd 'show module' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Please Enter Login Name:/
    password /^Please Enter Password:/
  end

  #handle pager with enable
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\r"
        send vars(:enable) + "\r"
      end
    end
    post_login 'skip-page-display'
    pre_logout 'logout'
    pre_logout 'exit'
    pre_logout 'exit'
  end

end
