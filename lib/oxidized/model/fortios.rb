class FortiOS < Oxidized::Model
  using Refinements

  comment '# '

  prompt /^([-\w.~]+(\s[(\w\-.)]+)?~?\s?[#>$]\s?)$/

  # When a post-login-banner is enabled, you have to press "a" to log in
  expect /^\(Press\s'a'\sto\saccept\):/ do |data, re|
    send 'a'
    data.sub re, ''
  end

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
    cfg.gsub! /(set privatekey ).*?-+END (ENCRYPTED|RSA|OPENSSH) PRIVATE KEY-+\n?"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set ca )"-+BEGIN.*?-+END CERTIFICATE-+"$/m, '\\1<configuration removed>'
    cfg.gsub! /(set csr ).*?-+END CERTIFICATE REQUEST-+"$/m, '\\1<configuration removed>'
    cfg
  end

  cmd 'get system status' do |cfg|
    @vdom_enabled = cfg.match /Virtual domain configuration: (enable|multiple)/
    cfg.gsub! /(System time:).*/, '\\1 <stripped>'
    cfg.gsub! /(Cluster (?:uptime|state change time):).*/, '\\1 <stripped>'
    cfg.gsub! /(Current Time\s+:\s+)(.*)/, '\1<stripped>'
    cfg.gsub! /(Uptime:\s+)(.*)/, '\1<stripped>\3'
    cfg.gsub! /(Last reboot:\s+)(.*)/, '\1<stripped>\3'
    cfg.gsub! /(Disk Usage\s+:\s+)(.*)/, '\1<stripped>'
    cfg.gsub! /(^\S+ (?:disk|DB):\s+)(.*)/, '\1<stripped>\3'
    cfg.gsub! /(VM Registration:\s+)(.*)/, '\1<stripped>\3'
    cfg.gsub! /(Virus-DB|Extended DB|FMWP-DB|IPS-DB|IPS-ETDB|APP-DB|INDUSTRIAL-DB|Botnet DB|IPS Malicious URL Database|AV AI\/ML Model|IoT-Detect).*/, '\\1 <db version stripped>'
    comment cfg
  end

  post do
    cfg = []
    cfg << cmd('config global') if @vdom_enabled

    cfg << cmd('get system ha status') do |cfg_ha|
      cfg_ha = cfg_ha.each_line.select { |line| line.match /^(HA Health Status|Mode|Model|Master|Slave|Primary|Secondary|# COMMAND)(\s+)?:/ }.join
      comment cfg_ha
    end

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

    # Different OS have different commands - we use the first that works
    # - For fortigate > 7 and possibly earlier versions, we use:
    #        show | grep .                     # backup as in fortigate GUI
    #        show full-configuration | grep .  # bakup including default values
    #   | grep is used to avoid the --More-- prompt
    # - It is not documented which systems need the commands without | grep:
    #        show full-configuration
    #        show
    #   Document it here and make a PR on github if you know!
    # By default, we use the configuration without default values
    # If fullconfig: true is set in the configuration, we get the full config
    commandlist = if vars(:fullconfig)
                    ['show full-configuration | grep .',
                     'show full-configuration', 'show']
                  else
                    ['show | grep .',
                     'show full-configuration', 'show']
                  end

    commandlist.each do |fullcmd|
      fullcfg = cmd(fullcmd)
      next if fullcfg.lines[1..3].join =~ /(Parsing error at|command parse error)/ # Don't show for unsupported devices (e.g. FortiAnalyzer, FortiManager, FortiMail)

      fullcfg.gsub! /(set comments "Error \(No order (found )?for (account )?ID \d+\) on).*/, '\\1 <stripped>"'

      cfg << fullcfg
      break
    end

    cfg.join
  end

  cfg :telnet do
    username /^[lL]ogin:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout "exit\n"
  end
end
