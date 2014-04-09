class TiMOS < Oxidized::Model

  # Alcatel-Lucent TiMOS (Timetra)
  # used in SR/ESS/SAS routers
 
  comment  '# '

  prompt /^([-\w\.:>\*]+\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].join
  end

  cmd 'show bof' do |cfg|
    comment cfg
  end

  cmd 'show system information' do |cfg|
    # strip uptime
    cfg.sub! /^System Up Time.*\n/, ''
    comment cfg
  end

  cmd 'show card state' do |cfg|
    comment cfg
  end

  cmd 'show boot-messages' do |cfg|
    cfg.gsub! /\r/, ""
    comment cfg
  end

  cmd 'admin display-config'

  cfg :telnet do
    username /^Login: /
    password /^Password: /
  end

  cfg :telnet, :ssh do
    post_login 'environment no more'
    pre_logout 'logout'
  end
end
