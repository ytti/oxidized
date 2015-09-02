class AOSW < Oxidized::Model

  # AOSW Aruba Wireless
  # Used in Alcatel OAW-4750 WLAN controller
  # Also Dell controllers

  comment  '# '
  prompt /^\([^)]+\) [#>]/

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.select { |line| not line.match /Switch uptime/i }
    comment cfg.join
  end

  cmd 'show inventory' do |cfg|
    clean cfg
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
    if vars :enable
      post_login do
        send 'enable\n'
        send vars(:enable) + '\n'
      end
    end
    post_login 'no paging'
    if vars :enable
      pre_logout 'exit'
    end
    pre_logout 'exit'
  end

  def clean cfg
    out = []
    cfg.each_line do |line|
      # drop the temperature, fan speed and voltage, which change each run
      next if line.match /Output \d Config/i
      next if line.match /(Tachometers|Temperatures|Voltages)/
      next if line.match /((Card|CPU) Temperature|Chassis Fan|VMON1[0-9])/
      next if line.match /[0-9]+ (RPM|mV|C)$/
      out << line.strip
    end
    out = comment out.join "\n"
    out << "\n"
  end

end
