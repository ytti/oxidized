class SROS < Oxidized::Model
  #
  # Nokia SR OS (TiMOS) (formerly TiMetra, Alcatel, Alcatel-Lucent).
  # Used in 7705 SAR, 7210 SAS, 7450 ESS, 7750 SR, 7950 XRS, and NSP.
  #

  comment  '# '

  prompt /^([-\w.:>*]+\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.cut_both
  end

  #
  # Show the boot options file.
  #
  cmd 'show bof' do |cfg|
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the system information.
  #
  cmd 'show system information' do |cfg|
    #
    # Strip uptime.
    #
    cfg.sub! /^System Up Time.*\n/, ''
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the card state.
  #
  cmd 'show card state' do |cfg|
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the boot log.
  #
  cmd 'file type bootlog.txt' do |cfg|
    #
    # Strip carriage returns and backspaces.
    #
    cfg.delete! "\r"
    cfg.gsub! /[\b][\b][\b]/, "\n"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the running debug configuration.
  #
  cmd 'show debug' do |cfg|
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the saved debug configuration (admin debug-save).
  #
  cmd 'file type config.dbg' do |cfg|
    #
    # Strip carriage returns.
    #
    cfg.delete! "\r"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the running persistent indices.
  #
  cmd 'admin display-config index' do |cfg|
    #
    # Strip carriage returns.
    #
    cfg.delete! "\r"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    comment cfg
  end

  #
  # Show the running configuration.
  #
  cmd 'admin display-config' do |cfg|
    #
    # Strip carriage returns.
    #
    cfg.delete! "\r"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
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
