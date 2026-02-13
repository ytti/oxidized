class ArubaInstant < Oxidized::Model
  using Refinements

  # Aruba IAP, Instant Controller

  comment '# '
  prompt(/^ ?[\w:.@-]+[#>] $/)

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
    cfg = cfg.reject_lines [
      /^(Switch|AP) uptime is /,
      /^Reboot Time and Cause/
    ]
    comment cfg
  end

  # Get serial number
  cmd 'show activate status' do |cfg|
    cfg = cfg.reject_lines [
      /^Activate /,
      /^Provision interval/,
      /^Cloud Activation Key/
    ]
    comment cfg + "\n"
  end

  # Get controlled WLAN-AP
  cmd 'show aps' do |cfg|
    out = ''
    cfg.each_line do |line|
      out += line.sub(
        /^(?'Name'(?:.+?|-{2,})\s{2,})  # \s{2,} = separator between columns
          (?'IPv4'(?:
            IP\ Address|-{2,}|          # Header
            (?:\d+\.){3}\S+             # Match an IPv4 to catch AP-Names with two spaces
          )\s{2,})
          (?:(?:.+?|-{2,})\s{2,}){3}    # Ignore Mode, Spectrum, Clients
          (?'Type'(?:.+?|-{2,})\s{2,})
          (?'IPv6'(?:.+?|-{2,})\s{2,})
          (?:(?:.+?|-{2,})\s{2,})       # Ignore Mesh Role
          (?'Zone'(?:.+?|-{2,})\s{2,})
          (?'Serial'(?:.+?|-{2,}))
          \s{2,}                        # Last separator
          .*$                           # Ignore the rest
          /x,
        '\k<Name>\k<IPv4>\k<Type>\k<IPv6>\k<Zone>\k<Serial>'
      )
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
