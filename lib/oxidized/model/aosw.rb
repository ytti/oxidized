class AOSW < Oxidized::Model

  # AOSW - Alcatel-Lucent OS - Wireless 
  # Used in Alcatel OAW-4750 WLAN controller (Aruba)

  comment  '# '
  prompt /^\([^)]+\) #/

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.select { |line| not line.match /Switch uptime/i }
    comment cfg
  end

  cmd 'show inventory' do |cfg|
    cfg = cfg.each_line.take_while { |line| not line.match /Main Board Temp/i }
    comment cfg
  end

  cmd 'show slots' do |cfg|
    comment cfg
  end
  cmd 'show license' do |cfg|
    comment cfg
  end
  cmd 'show configuration' do |cfg|
    cfg
  end

  cfg :telnet do
    username /^User:\s*/
    password /^Password:\s*/
  end

  cfg :telnet, :ssh do
    post_login 'no paging'
    pre_logout 'exit'
  end

end
