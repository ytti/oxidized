class SROS_ISAM < Oxidized::Model
  #
  # Nokia SR OS (TiMOS) used in the ISAM platform (Nokia 7360)
  #

  comment  '# '

  prompt /^([-\w.:>*]+\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    cfg.delete! "\r"
    new_cfg << cfg.cut_both
  end

  # Show the ports
  #
  cmd 'show port' do |cfg|
    comment cfg
  end

  # Show the equipment shelf
  #
  cmd 'show equipment shelf' do |cfg|
    comment cfg
  end

  # Show the equipment slot
  #
  cmd 'show equipment slot' do |cfg|
    comment cfg
  end

  # Show the equipment transceiver-inventory
  #
  cmd 'show equipment transceiver-inventory' do |cfg|
    comment cfg
  end

  # Show the equipment ont interface
  #
  cmd 'show equipment ont interface' do |cfg|
    comment cfg
  end

  # Show the equipment ont slot
  #
  cmd 'show equipment ont slot' do |cfg|
    comment cfg
  end

  # Show configuration
  cmd 'info configure' do |cfg|
    cfg
  end


  cfg :telnet do
    username /^Login: /
    password /^Password: /
  end

  cfg :telnet, :ssh do
    post_login 'environment no terminal-timeout'
    post_login 'environment print no-more'
    post_login 'environment inhibit-alarms'
    pre_logout 'logout'
  end
end

