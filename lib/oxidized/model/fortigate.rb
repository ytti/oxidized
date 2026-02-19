class FortiGate < Oxidized::Model
  using Refinements

  comment '# '

  prompt /^(\(\w\) )?([-\w.~]+(\s[(\w\-.)]+)?~?\s?[#>$]\s?)$/

  # When a post-login-banner is enabled, you have to press "a" to log in
  expect /^\(Press\s'a'\sto\saccept\):/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  expect /^--More--\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    # Remove junk after --More-- pager
    cfg = cfg.gsub(/\r +\r/, '')
    # Remove \r\n after command echo
    cfg = cfg.gsub("\r\n", "\n")
    # remove command echo and prompt
    cfg.cut_both
  end

  cmd :secret do |cfg|
    # Remove private key for encrypted configs
    cfg.gsub! /^(\#private-encryption-key=).+/, '\\1 <configuration removed>'
    # ENC indicates an encrypted password, and secret indicates a secret string
    cfg.gsub! /(set .+ ENC) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set .*secret) .+/, '\\1 <configuration removed>'
    # A number of other statements also contains sensitive strings
    cfg.gsub! /(set (?:passwd|password|key|group-password|auth-password-l1|auth-password-l2|rsso|history0|history1)) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set md5-key [0-9]+) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set private-key ).*?-+END (ENCRYPTED|RSA|OPENSSH) PRIVATE KEY-+\n?"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set privatekey ).*?-+END (ENCRYPTED|RSA|OPENSSH) PRIVATE KEY-+\n?"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set ca )"-+BEGIN.*?-+END CERTIFICATE-+"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set csr ).*?-+END CERTIFICATE REQUEST-+"$/m, '\\1<configuration removed>'
    cfg
  end

  cmd 'get system status' do |cfg|
    @vdom_enabled = cfg.match(/^Virtual domain configuration: (enable|multiple)/)
    @ha_cluster = cfg.match(/^Current HA mode: a-/) # a-p or a-a
    cfg = cfg.keep_lines [
      "Version: ",
      "Security Level: ",
      "Serial-Number: ",
      "BIOS version: ",
      "System Part-Number: ",
      "Hostname: ",
      "Operation Mode: ",
      "Current virtual domain: ",
      "Max number of virtual domains: ",
      "Virtual domains status:",
      "Virtual domain configuration: ",
      "FIPS-CC mode: ",
      "Current HA mode: ",
      "Private Encryption: ",
      # Lines in FortiGate-VM64
      "License Expiration Date: ",
      "License Status: ",
      "VM Resources: "
    ]
    comment cfg + "\n"
  end

  cmd 'config global', if: -> { @vdom_enabled } do |_cfg|
    ''
  end

  cmd 'get system ha status', if: -> { @ha_cluster } do |cfg|
    cfg = cfg.keep_lines [
      "HA Health Status:",
      "Model: ",
      "Mode: ",
      "number of member: ",
      /^(Master|Slave|Primary|Secondary): /
    ]
    comment cfg + "\n"
  end

  cmd 'get hardware status' do |cfg|
    comment cfg
  end

  cmd "diagnose hardware deviceinfo psu" do |cfg|
    skip_patterns = [
      /Command fail\./,      # The device doesn't support this command
      /Power Supply +Status/ # We only get a status, but no serial numbers
    ]
    if skip_patterns.any? { |p| cfg.match?(p) }
      logger.debug "No PSU serial numbers available"
      ''
    else
      comment cfg
    end
  end

  cmd "get system interface transceiver" do |cfg|
    cfg = cfg.keep_lines [
      /^Interface \w/,
      "Vendor Name",
      "Part No./",
      "Serial No."
    ]
    cfg = cfg.reject_lines ["Transceiver is not detected"]
    comment cfg + "\n"
  end

  cmd 'diagnose autoupdate version', if: -> { vars(:fortios_autoupdate) || vars(:fortigate_autoupdate) } do |cfg|
    if vars(:fortios_autoupdate)
      logger.warn("The variable fortios_autoupdate is deprecated. Migrate to fortigate_autoupdate")
    end

    cfg = cfg.sub(/FDS Address\n---------\n.*\n/, '')
    comment cfg.reject_lines ["Last Update", "Result :"]
  end

  cmd 'end', if: -> { @vdom_enabled } do |_cfg|
    ''
  end

  def clean_config(cfg)
    cfg = cfg.reject_lines ['#conf_file_ver=']
    cfg.gsub!(/(set comments "Error \(No order found for account ID \d+\) on).*/,
              '\\1 <stripped>')
    cfg
  end

  # If vars fullconfig is set to true, we get the full config (including default
  # values)
  cmd "show full-configuration | grep .", if: -> { vars(:fullconfig) } do |cfg|
    clean_config cfg
  end
  # else backup as in Fortigate GUI
  cmd "show | grep .", if: -> { !vars(:fullconfig) } do |cfg|
    clean_config cfg
  end

  cmd :significant_changes do |cfg|
    cfg = cfg.reject_lines [
      /^ +set \S+ ENC \S+$/
    ]
    cfg.gsub!(/(config firewall internet-service-name\n).*?(\nend\n)/m, '')
    cfg.gsub!(/set private-key .*?-+END \S+ PRIVATE KEY-+\n?"$/m, '')
    cfg
  end

  cfg :telnet do
    username /^[lL]ogin:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout "exit"
  end
end
