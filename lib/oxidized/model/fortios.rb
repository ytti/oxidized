class FortiOS < Oxidized::Model

  comment  '# '

  prompt /^([-\w\.]+(\s[\(\w\-\.\)]+)?\~?\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].join
  end

  cmd 'get system status' do |cfg|
    @vdom_enabled = cfg.include? 'Virtual domain configuration: enable'
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
    post_login 'config global'
    post_login 'config system console'
    post_login 'set output standard'
    post_login 'end'
    post_login 'end'
    pre_logout 'config system console'
    pre_logout 'set output more'
    pre_logout 'end'
    pre_logout "exit\n"
  end

end
