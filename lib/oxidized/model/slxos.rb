class SLXOS < Oxidized::Model
  prompt /^.*[>#]\s?$/i
  comment '! '

  cmd 'show version' do |cfg|
    cfg.gsub! /(^((.*)[Ss]ystem [Uu]ptime(.*))$)/, '' # remove unwanted line system uptime
    cfg.gsub! /[Uu]p\s?[Tt]ime is .*/, ''

    comment cfg
  end

  cmd 'show chassis' do |cfg|
    cfg.encode!("UTF-8", invalid: :replace, undef: :replace) # sometimes ironware returns broken encoding
    cfg.gsub! /.*Power Usage.*/, '' # remove unwanted lines power usage
    cfg.gsub! /Time A(live|wake).*/, '' # remove unwanted lines time alive/awake
    cfg.gsub! /([\[]*)1([\]]*)<->([\[]*)2([\]]*)(<->([\[]*)3([\]]*))*/, ''

    comment cfg
  end

  cmd 'show system' do |cfg|
    cfg.gsub! /Up Time.*/, '' # removes uptime line
    cfg.gsub! /Current Time.*/, '' # remove current time line
    cfg.gsub! /.*speed is.*/, '' # removes fan speed lines

    comment cfg
  end

  cmd 'show slots' do |cfg|
    cfg.gsub! /^-*^$/, '' # some slx devices are fixed config
    cfg.gsub! /syntax error: element does not exist/, '' # same as above

    comment cfg
  end

  cmd 'show running-config' do |cfg|
    arr = cfg.each_line.to_a
    arr[2..-1].join unless arr.length < 2
  end

  cfg :telnet do
    # match expected prompts
    username /^(Please Enter Login Name|Username):/
    password /^(Please Enter Password ?|Password):/
  end

  # handle pager with enable
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login ''
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
