class SROSMD < Oxidized::Model
  using Refinements

  #
  # Nokia SR OS (TiMOS) (formerly TiMetra, Alcatel, Alcatel-Lucent)
  # Working in Model-Driven CLI mode.
  # Used in 7705 SAR, 7210 SAS, 7450 ESS, 7750 SR, 7950 XRS, and NSP.
  #

  comment '# '

  prompt /^([-\w.@:>*]+\s?[#>]\s?)$/

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    cfg.gsub! /# Finished .*/, ''
    cfg.gsub! /# Generated .*/, ''
    cfg.delete! "\r"
    new_cfg << cfg.cut_both
  end

  #
  # Show the system information.
  #
  cmd 'show system information' do |cfg|
    #
    # Strip uptime.
    #
    cfg.gsub! /^System Up Time.*\n/, ''
    comment cfg
  end

  #
  # Show the card state.
  #
  cmd 'show card state' do |cfg|
    comment cfg
  end

  #
  # Show the chassis information.
  #
  cmd 'show chassis' do |cfg|
    comment cfg.lines.to_a[0..25].reject { |line| line.match /state|Time|Temperature|Status/ }.join
  end

  #
  # Show the boot log.
  #
  cmd 'file show bootlog.txt' do |cfg|
    cfg.gsub! /[\b][\b][\b]/, "\n"
    comment cfg
  end

  #
  # Show the running debug configuration.
  #
  cmd 'admin show configuration debug full-context' do |cfg|
    comment cfg
  end

  #
  # Show the saved debug configuration (admin debug-save).
  #
  cmd 'file show config.dbg' do |cfg|
    comment cfg
  end

  #
  # Show the running persistent indices.
  #
  cmd 'admin show configuration configure | match persistent-indices post-lines 10000' do |cfg|
    comment cfg
  end

  #
  # Show the boot options file.
  #
  cmd 'admin show configuration bof full-context' do |cfg|
    cfg
  end

  #
  # Show the running configuration.
  #
  cmd 'admin show configuration configure full-context' do |cfg|
    cfg
  end

  cfg :telnet do
    username /^Login: /
    password /^Password: /
  end

  cfg :telnet, :ssh do
    post_login 'environment more false'
    pre_logout 'logout'
  end
end
