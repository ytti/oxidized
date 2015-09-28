class IronWare < Oxidized::Model

  prompt /^.*(telnet|ssh)\@.+[>#]\s?$/i
  comment  '! '
  
  #to handle pager without enable
  #expect /^((.*)--More--(.*))$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  #end

  
  #to remove backspace (if handle pager without enable)
  #expect /^((.*)[\b](.*))$/ do |data, re|
  #  data.sub re, ''
  #end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[3..-1].join unless arr.length < 3
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /(^((.*)[Ss]ystem uptime(.*))$)/, '' #remove unwanted line system uptime
    cfg.gsub! /[Uu]p\s?[Tt]ime is .*/,''

    comment cfg
  end

  cmd 'show chassis' do |cfg|
    cfg.encode!("UTF-8", :invalid => :replace) #sometimes ironware returns broken encoding
    cfg.gsub! /(^((.*)Current temp(.*))$)/, '' #remove unwanted lines current temperature
    cfg.gsub! /Speed = [A-Z]{3} \(\d{2}\%\)/, '' #remove unwanted lines Speed Fans
    cfg.gsub! /current speed is [A-Z]{3} \(\d{2}\%\)/, ''
    cfg.gsub! /\d{2}\.\d deg-C/, 'XX.X deg-C'
    if cfg.include? "TEMPERATURE"
      sc = StringScanner.new cfg
      out = ''
      temps = ''
      out << sc.scan_until(/.*TEMPERATURE/)
      temps << sc.scan_until(/.*Fans/)
      out << sc.rest
      cfg = out
    end
    
    comment cfg
  end
  
  cmd 'show flash' do |cfg|
    comment cfg
  end
  
  cmd 'show module' do |cfg|
    comment cfg
  end

  cfg :telnet do
    # match expected prompts on both older and newer
    # versions of IronWare
    username /^(Please Enter Login Name|Username):/
    password /^(Please Enter )Password:/
  end

  #handle pager with enable
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\r\n"
        send vars(:enable) + "\r\n"
      end
    end
    post_login ''
    post_login 'skip-page-display'
    post_login 'terminal length 0'
    pre_logout 'logout'
    pre_logout 'exit'
    pre_logout 'exit'
  end

end
