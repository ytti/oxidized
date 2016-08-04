class TiMOS < Oxidized::Model

  #
  # Nokia SR OS (TiMOS) (formerly TiMetra, Alcatel, Alcatel-Lucent).
  # Used in 7705 SAR, 7210 SAS, 7450 ESS, 7750 SR, 7950 XRS, and NSP.
  #

  # 
  # Define comment but don't actually use it.  SR OS has a lot of output that
  # is exactly 80 columns wide, and the comment make the output look funny.
  #
  comment  '# '

  prompt /^([-\w\.:>\*]+\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].join
  end

  #
  # Show the boot options file.
  #
  cmd 'show bof'

  #
  # Show the system information.
  #
  cmd 'show system information' do |cfg|
    #
    # Strip uptime.
    #
    cfg.sub! /^System Up Time.*\n/, ''
  end

  #
  # Show the card state.
  #
  cmd 'show card state'

  #
  # Show the boot log.
  #
  cmd 'file type bootlog.txt' do |cfg|
    #
    # Strip carriage returns and backspaces.
    #
    cfg.gsub! /\r/, ''
    cfg.gsub! /[\b][\b][\b]/, "\n"
  end

  #
  # Show the running debug configuration.
  #
  cmd 'show debug'

  #
  # Show the saved debug configuration (admin debug-save).
  #
  cmd 'file type config.dbg' do |cfg|
    #
    # Strip carriage returns.
    #
    cfg.gsub! /\r/, ''
  end

  #
  # Show the running persistent indices.
  #
  cmd 'admin display-config index' do |cfg|
    #
    # Strip carriage returns.
    #
    cfg.gsub! /\r/, ''
  end

  #
  # Show the running configuration.
  #
  cmd 'admin display-config' do |cfg|
    #
    # Strip carriage returns.
    #
    cfg.gsub! /\r/, ''
  end

  cfg :telnet do
    username /^Login: /
    password /^Password: /
  end

  cfg :telnet, :ssh do
    post_login 'environment no more'
    pre_logout 'logout'
  end
end
