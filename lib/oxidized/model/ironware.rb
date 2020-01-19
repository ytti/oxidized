class IronWare < Oxidized::Model
  prompt /^.*(telnet|ssh)@.+[>#]\s?$/i
  comment  '! '

  # to handle pager without enable
  # expect /^((.*)--More--(.*))$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  # to remove backspace (if handle pager without enable)
  # expect /^((.*)[\b](.*))$/ do |data, re|
  #  data.sub re, ''
  # end

  cmd :all do |cfg|
    # sometimes ironware inserts arbitrary whitespace after commands are
    # issued on the CLI, from run to run.  this normalises the output.
    cfg.each_line.to_a[1..-2].drop_while { |e| e.match /^\s+$/ }.join
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /(^((.*)[Ss]ystem uptime(.*))$)/, '' # remove unwanted line system uptime
    cfg.gsub! /(^((.*)[Tt]he system started at(.*))$)/, ''
    cfg.gsub! /[Uu]p\s?[Tt]ime is .*/, ''

    comment cfg
  end

  cmd 'show chassis' do |cfg|
    cfg.encode!("UTF-8", invalid: :replace, undef: :replace) # sometimes ironware returns broken encoding
    cfg.gsub! /(^((.*)Current temp(.*))$)/, '' # remove unwanted lines current temperature
    cfg.gsub! /Speed = [A-Z-]{2,6} \(\d{2,3}%\)/, '' # remove unwanted lines Speed Fans
    cfg.gsub! /current speed is [A-Z]{2,6} \(\d{2,3}%\)/, ''
    cfg.gsub! /Fan \d* - STATUS: OK \D*\d*./, '' # Fix for ADX Fan speed reporting
    cfg.gsub! /\d* deg C/, '' # Fix for ADX temperature reporting
    cfg.gsub! /([\[]*)1([\]]*)<->([\[]*)2([\]]*)(<->([\[]*)3([\]]*))*/, ''
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
    cfg.gsub! /(\d+) bytes/, '' # Fix for ADX flash size
    cfg.gsub! /(^((.*)Code Flash Free Space(.*))$)/, '' # Brocade
    comment cfg
  end

  cmd 'show module' do |cfg|
    cfg.gsub! /^((Invalid input)|(Type \?)).*$/, '' # some ironware devices are fixed config
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[2..-1].join unless arr.length < 2
  end

  cfg :telnet do
    # match expected prompts on both older and newer
    # versions of IronWare
    username /^(Please Enter Login Name|Username):/
    password /^(Please Enter Password ?|Password):/
  end

  # handle pager with enable
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\r\n"
        cmd vars(:enable)
      end
    end
    post_login ''
    post_login 'skip-page-display'
    post_login 'terminal length 0'
    pre_logout "logout\nexit\nexit\n"
  end
end
