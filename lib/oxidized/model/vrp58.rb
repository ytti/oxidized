class VRP58 < Oxidized::Model
  # Huawei VRP MA5800

  prompt /^([\w.-]+(>|#))$/
  comment '# '

  cmd :secret do |cfg|
    cfg.gsub! /(pin verify (?:auto|)).*/, '\\1 <PIN hidden>'
    cfg.gsub! /(%\^%#.*%\^%#)/, '<secret hidden>'
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cfg :telnet do
    username /^(>>User name:)$/
    password /^(>>User password:)$/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    post_login 'undo echo'
    post_login "scroll \n"
    post_login 'undo interactive'
    post_login 'infoswitch cli off'
    pre_logout "quit"
  end

  cmd "display board serial-number 0 \n" do |cfg|
    comment cfg
  end

  cmd "display board desc 0 \n" do |cfg|
    comment cfg
  end

  cmd "display io-packetfile information \n" do |cfg|
    comment cfg
  end

  cmd "display version \n" do |cfg|
    cfg = cfg.each_line.select {|l| not l.match /Uptime/ }.join
    comment cfg
  end

  cmd "display current-configuration \n" do |cfg|
    cfg
  end

end

