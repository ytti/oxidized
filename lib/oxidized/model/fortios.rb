class FortiOS < Oxidized::Model

  comment  '# '

  prompt /^([-\w\.\~]+(\s[\(\w\-\.\)]+)?\~?\s?[#>$]\s?)$/

  expect /^--More--\s$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].map { |line| line.gsub(/(conf_file_ver=)(.*)/, '\1<stripped>\3') }.join
  end

  cmd :secret do |cfg|
    cfg.gsub! /(set (?:passwd|password|psksecret|secret|key|group-password|secondary-secret|tertiary-secret|auth-password-l1|auth-password-l2|rsso|history0|history1|inter-controller-key ENC)).*/, '\\1 <configuration removed>'
    cfg.gsub! /(set private-key).*-+END ENCRYPTED PRIVATE KEY-*"$/m , '\\1 <configuration removed>'
    cfg.gsub! /(set ca ).*-+END CERTIFICATE-*"$/m , '\\1 <configuration removed>'
    cfg.gsub! /(set csr ).*-+END CERTIFICATE REQUEST-*"$/m , '\\1 <configuration removed>'
    cfg.gsub! /(Virus-DB|Extended DB|IPS-DB|IPS-ETDB|APP-DB|INDUSTRIAL-DB|Botnet DB|IPS Malicious URL Database).*/, '\\1 <configuration removed>'
    cfg.gsub! /(Cluster uptime:).*/, '\\1 <configuration removed>'
    cfg
  end

  cmd 'get system status' do |cfg|
    @vdom_enabled = cfg.include? 'Virtual domain configuration: enable'
    cfg.gsub!(/(System time: )(.*)/, '\1<stripped>\3')
    comment cfg
  end

  post do
    cfg = []
    cfg << cmd('config global') if @vdom_enabled

    cfg << cmd('get hardware status') do |cfg|
       comment cfg
    end

    #default behaviour: include autoupdate output (backwards compatibility)
    #do not include if variable "show_autoupdate" is set to false
    if  defined?(vars(:fortios_autoupdate)).nil? || vars(:fortios_autoupdate)
       cfg << cmd('diagnose autoupdate version') do |cfg|
          cfg.gsub! /(FDS Address\n---------\n).*/, '\\1IP Address removed'
          comment cfg.each_line.reject { |line| line.match /Last Update|Result/ }.join
       end
    end

cfg << cmd('end') if @vdom_enabled

    cfg << cmd('show full-configuration')
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

