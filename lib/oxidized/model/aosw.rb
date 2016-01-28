class AOSW < Oxidized::Model

  # AOSW Aruba Wireless
  # Used in Alcatel OAW-4750 WLAN controller
  # Also Dell controllers

  comment  '# '
  prompt /^\([^)]+\) [#>]/

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub!(/PRE-SHARE (\S+)$/, 'PRE-SHARE <secret removed>')
    cfg.gsub!(/ipsec (\S+)$/, 'ipsec <secret removed>')
    cfg.gsub!(/community (\S+)$/, 'community <secret removed>')
    cfg.gsub!(/ sha (\S+)/, ' sha <secret removed>')
    cfg.gsub!(/ des (\S+)/, ' des <secret removed>')
    cfg.gsub!(/mobility-manager (\S+) user (\S+) (\S+)/, 'mobility-manager \1 user \2 <secret removed>')
    cfg.gsub!(/mgmt-user (\S+) (\S+) (\S+)$/, 'mgmt-user \1 \2 <secret removed>')
    cfg.gsub!(/key (\S+)$/, 'key <secret removed>')
    cfg.gsub!(/secret (\S+)$/, 'secret <secret removed>')
    cfg.gsub!(/wpa-passphrase (\S+)$/, 'wpa-passphrase <secret removed>')
    cfg
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
  cmd 'show running-config' do |cfg|
    out = []
    cfg.each_line do |line|
      next if line.match /^controller config \d+$/
      next if line.match /^Building Configuration/
      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
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
    post_login 'encrypt disable'
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
      next if line.match /[0-9]+ (RPMS?|m?V|C)/i
      out << line.strip
    end
    out = comment out.join "\n"
    out << "\n"
  end

end
