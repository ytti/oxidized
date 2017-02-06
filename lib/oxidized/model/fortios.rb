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
    cfg.gsub! /(set (?:passwd|password)).*/, '\\1 <configuration removed>'
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

    cfg << cmd('diagnose autoupdate version') do |cfg|
      comment cfg
    end

    cfg << cmd('end') if @vdom_enabled

    cfg << cmd('show')
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
