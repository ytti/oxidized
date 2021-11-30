class FortiOS < Oxidized::Model
  comment '# '

  prompt /^([-\w.~]+(\s[(\w\-.)]+)?~?\s?[#>$]\s?)$/

  expect /^--More--\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
  end

  cmd :secret do |cfg|
    # ENC indicates an encrypted password, and secret indicates a secret string
    cfg.gsub! /(set .+ ENC) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set .*secret) .+/, '\\1 <configuration removed>'
    # A number of other statements also contains sensitive strings
    cfg.gsub! /(set (?:passwd|password|key|group-password|auth-password-l1|auth-password-l2|rsso|history0|history1)) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set md5-key [0-9]+) .+/, '\\1 <configuration removed>'
    cfg.gsub! /(set private-key ).*?-+END (ENCRYPTED|RSA|OPENSSH) PRIVATE KEY-+\n?"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set ca ).*?-+END CERTIFICATE-+"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set csr ).*?-+END CERTIFICATE REQUEST-+"$/m, '\\1<configuration removed>'
    cfg
  end

  cmd 'get system status' do |cfg|
    @vdom_enabled = cfg.match /Virtual domain configuration: (enable|multiple)/
    cfg.gsub! /(System time:).*/, '\\1 <stripped>'
    cfg.gsub! /(Cluster uptime:).*/, '\\1 <stripped>'
    cfg.gsub! /(Virus-DB|Extended DB|IPS-DB|IPS-ETDB|APP-DB|INDUSTRIAL-DB|Botnet DB|IPS Malicious URL Database).*/, '\\1 <db version stripped>'
    comment cfg
  end

  cmd 'get system ha status' do |cfg|
    cfg = cfg.each_line.select { |line| line.match /^(HA Health Status|Mode|Model|Master|Slave\s+):/ }.join
    comment cfg
  end

  post do
    cfg = []
    cfg << cmd('config global') if @vdom_enabled

    cfg << cmd('get hardware status') do |cfg_hw|
      comment cfg_hw
    end

    # default behaviour: include autoupdate output (backwards compatibility)
    # do not include if variable "show_autoupdate" is set to false
    if defined?(vars(:fortios_autoupdate)).nil? || vars(:fortios_autoupdate)
      cfg << cmd('diagnose autoupdate version') do |cfg_auto|
        cfg_auto.gsub! /(FDS Address\n---------\n).*/, '\\1IP Address removed'
        comment cfg_auto.each_line.reject { |line| line.match /Last Update|Result/ }.join
      end
    end

    cfg << cmd('end') if @vdom_enabled

    cfg << cmd('show full-configuration | grep .')
    cfg.join "\n"
  end

  cfg :telnet do
    username /login:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout "exit\n"
  end
end
