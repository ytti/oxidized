class AOSW < Oxidized::Model

  # AOSW Aruba Wireless
  # Used in Alcatel OAW-4750 WLAN controller
  # Also Dell controllers

  comment  '# '
  prompt /^\([^)]+\) #/

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.select { |line| not line.match /Switch uptime/i }
    comment cfg.join
  end

  cmd 'show inventory' do |cfg|
    cfg = cfg.each_line.take_while { |line| not line.match /Output \d Config/i }
    # drop the temperature, fan speed and voltage, which change each run
    cfg.gsub! /[0-9]+ (RPM|mV|C)\n/, ''
    comment cfg.join
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
