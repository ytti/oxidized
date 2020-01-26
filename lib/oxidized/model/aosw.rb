class AOSW < Oxidized::Model
  # AOSW Aruba Wireless, IAP, Instant Controller and Mobility Access Switches
  # Used in Alcatel OAW-4750 WLAN controller
  # Also Dell controllers

  # HPE Aruba Switches should use a different model as the software is based on the HP Procurve line.

  # Support for IAP & Instant Controller tested with 115, 205, 215 & 325 running 6.4.4.8-4.2.4.5_57965
  # Support for Mobility Access Switches tested with S2500-48P & S2500-24P running 7.4.1.4_54199 and S2500-24P running 7.4.1.7_57823
  # All IAPs connected to a Instant Controller will have the same config output. Only the controller needs to be monitored.

  comment  '# '
  prompt /^([\w\(:.@-]+(\)?\s?)[#>]\s?)$/

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub!(/secret (\S+)$/, 'secret <secret removed>')
    cfg.gsub!(/enable secret (\S+)$/, 'enable secret <secret removed>')
    cfg.gsub!(/PRE-SHARE (\S+)$/, 'PRE-SHARE <secret removed>')
    cfg.gsub!(/ipsec (\S+)$/, 'ipsec <secret removed>')
    cfg.gsub!(/community (\S+)$/, 'community <secret removed>')
    cfg.gsub!(/ sha (\S+)/, ' sha <secret removed>')
    cfg.gsub!(/ des (\S+)/, ' des <secret removed>')
    cfg.gsub!(/mobility-manager (\S+) user (\S+) (\S+)/, 'mobility-manager \1 user \2 <secret removed>')
    cfg.gsub!(/mgmt-user (\S+) (root|guest-provisioning|network-operations|read-only|location-api-mgmt) (\S+)$/, 'mgmt-user \1 \2 <secret removed>') # MAS & Wireless Controler
    cfg.gsub!(/mgmt-user (\S+) (\S+)( (read-only|guest-mgmt))?$/, 'mgmt-user \1 <secret removed> \3') # IAP
    # MAS format: mgmt-user <username> <accesslevel> <password hash>
    # IAP format (root user): mgmt-user <username> <password hash>
    # IAP format: mgmt-user <username> <password hash> <access level>
    cfg.gsub!(/key (\S+)$/, 'key <secret removed>')
    cfg.gsub!(/wpa-passphrase (\S+)$/, 'wpa-passphrase <secret removed>')
    cfg.gsub!(/bkup-passwords (\S+)$/, 'bkup-passwords <secret removed>')
    cfg.gsub!(/user (\S+) (\S+) (\S+)$/, 'user \1 <secret removed> \3')
    cfg.gsub!(/virtual-controller-key (\S+)$/, 'virtual-controller-key <secret removed>')
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /(Switch|AP) uptime/i }
    rstrip_cfg comment cfg.join
  end

  cmd 'show inventory' do |cfg|
    cfg = "" if cfg =~ /(Invalid input detected at '\^' marker|Parse error)/ # Don't show for unsupported devices (IAP and MAS)
    rstrip_cfg clean cfg
  end

  cmd 'show slots' do |cfg|
    cfg = "" if cfg =~ /(Invalid input detected at '\^' marker|Parse error)/ # Don't show for unsupported devices (IAP and MAS)
    rstrip_cfg comment cfg
  end

  cmd 'show license' do |cfg|
    cfg = "" if cfg =~ /(Invalid input detected at '\^' marker|Parse error)/ # Don't show for unsupported devices (IAP and MAS)
    rstrip_cfg comment cfg
  end

  cmd 'show license passphrase' do |cfg|
    cfg = "" if cfg.match /(Invalid input detected at '\^' marker|Parse error)/ # Don't show for unsupported devices (IAP and MAS)
    rstrip_cfg comment cfg
  end

  cmd 'show running-config' do |cfg|
    out = []
    cfg.each_line do |line|
      next if line =~ /^controller config \d+$/
      next if line =~ /^Building Configuration/

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
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'no paging'
    post_login 'encrypt disable'
    pre_logout 'exit' if vars :enable
    pre_logout 'exit'
  end

  def rstrip_cfg(cfg)
    out = []
    cfg.each_line do |line|
      out << line.rstrip
    end
    out = out.join "\n"
    out << "\n"
  end

  def clean(cfg)
    out = []
    cfg.each_line do |line|
      # drop the temperature, fan speed and voltage, which change each run
      next if line =~ /Output \d Config/i
      next if line =~ /(Tachometers|Temperatures|Voltages)/
      next if line =~ /((Card|CPU) Temperature|Chassis Fan|VMON1[0-9])/
      next if line =~ /[0-9]+\s+(RPMS?|m?V|C)/i

      out << line.strip
    end
    out = comment out.join "\n"
    out << "\n"
  end
end
