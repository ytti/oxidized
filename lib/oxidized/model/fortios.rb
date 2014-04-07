class FortiOS < Oxidized::Model

  comment  '# '

  prompt /^([-\w\.]+(\s[\(\w\-\.\)]+)?\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].join
  end

  cmd 'get system status' do |cfg|
    comment cfg
  end

  cmd 'config global'

  cmd 'get hardware status' do |cfg|
    comment cfg
  end

  cmd 'diagnose autoupdate version' do |cfg|
    comment cfg
  end

  cmd 'end'

  cmd 'show'

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout "exit\n"
  end

end
