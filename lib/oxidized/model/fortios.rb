class FortiOS < Oxidized::Model
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
    cfg = cfg.reject_lines [
      "Current Time",
      "Disk Usage",
      "Release Version Information",
      "Branch Point",
      "Daylight Time Saving",
      "Time Zone",
      "x86-64 Applications",
      "File System",
      "Image Signature"
    ]
    comment cfg + "\n"
  end

  cmd "show" do |cfg|
    cfg.reject_lines ['#config-version=']
  end

  cmd :significant_changes do |cfg|
    cfg = cfg.reject_lines [
      /^ +set \S+ ENC \S+$/
    ]
    cfg.gsub(/set private-key .*?-+END \S+ PRIVATE KEY-+\n?"$/m, '')
  end

  cfg :telnet do
    username /^[lL]ogin:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout "exit"
  end
end
