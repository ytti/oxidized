class ArubaInstant < Oxidized::Model
  using Refinements

  # Aruba IAP, Instant Controller

  comment '# '
  prompt(/^ ?[\w\:.@-]+[#>] $/)

  cmd :all do |cfg|
    # Remove command echo and prompt
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub!(/ipsec (\S+)$/, 'ipsec <secret removed>')
    cfg.gsub!(/community (\S+)$/, 'community <secret removed>')
    cfg.gsub!(/^(snmp-server host [\d.]+ version 2c) \S+ (.*)$/, '\1 <secret removed> \2')
    # MAS format: mgmt-user <username> <accesslevel> <password hash>
    # IAP format (root user): mgmt-user <username> <password hash>
    # IAP format: mgmt-user <username> <password hash> <access level>
    cfg.gsub!(/mgmt-user (\S+) (root|guest-provisioning|network-operations|read-only|location-api-mgmt) (\S+)$/, 'mgmt-user \1 \2 <secret removed>') # MAS & Wireless Controler
    cfg.gsub!(/mgmt-user (\S+) (\S+)( (read-only|guest-mgmt))?$/, 'mgmt-user \1 <secret removed> \3') # IAP
    cfg.gsub!(/key (\S+)$/, 'key <secret removed>')
    cfg.gsub!(/wpa-passphrase (\S+)$/, 'wpa-passphrase <secret removed>')
    cfg.gsub!(/bkup-passwords (\S+)$/, 'bkup-passwords <secret removed>')
    cfg.gsub!(/user (\S+) (\S+) (\S+)$/, 'user \1 <secret removed> \3')
    cfg.gsub!(/virtual-controller-key (\S+)$/, 'virtual-controller-key <secret removed>')
    cfg.gsub!(/^(hash-mgmt-user .* password \S+) \S+( usertype .*)?$/, '\1 <secret removed>\2')
    cfg
  end

  # get software version
  cmd 'show version' do |cfg|
    out = ''
    cfg.each_line do |line|
      next if line =~ /^(Switch|AP) uptime is /

      next if line =~ /^Reboot Time and Cause/

      out += line
    end
    comment out
  end

  # Get serial number
  cmd 'show activate status' do |cfg|
    out = ''
    cfg.each_line do |line|
      next if line =~ /^Activate /

      next if line =~ /^Provision interval/

      next if line =~ /^Cloud Activation Key/

      out += line
    end
    comment out + "\n"
  end

  # Get controlled WLAN-AP
  cmd 'show aps' do |cfg|
    out = ''
    cfg.each_line do |line|
      out += if line.match?(/^Name/)
               line.sub(/^(Name +IP Address +).*(Type +IPv6 Address +).*(Serial #).*$/, '\1\2\3')
             else
               line.sub(/^(\S+ +\S+ +)(?:\S+ +){3}(\S+ +\S+ +)(?:\S+ +){2}(\S+) +.*$/, '\1\2\3')
             end
    end
    comment out + "\n"
  end

  cmd 'show running-config no-encrypt'

  cfg :telnet do
    username(/^User:\s*/)
    password(/^Password:\s*/)
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    pre_logout 'exit' if vars :enable
    pre_logout 'exit'
  end
end
