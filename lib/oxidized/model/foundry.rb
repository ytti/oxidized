class FOUNDRY < Oxidized::Model

  # Brocade Network Operating System

  prompt /([\w.@()-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show license' do |cfg|
    comment cfg
  end

  cmd 'show chassis' do |cfg|
    comment cfg.each_line.reject { |line| line.match /Time/ }.join
  end

  cfg 'show system' do |cfg|
    comment cfg.each_line.reject { |line| line.match /Time/ or line.match /speed/ }
  end

  cmd 'show running-config'

  cfg :telnet do
    username /^.* login: /
    username /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'skip-page-display'
    #post_login 'terminal width 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end

end
