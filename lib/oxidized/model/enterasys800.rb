class Enterasys800 < Oxidized::Model
  using Refinements

  # Enterasys 800 models #
  # Tested with 08H20G4-24 Fast Ethernet Switch Firmware: Build 01.01.01.0017
  comment '# '

  prompt /([\w \(:.@-]+[#>]\s?)$/

  cfg :telnet do
    username /UserName:/
    password /PassWord:/
  end

  cfg :telnet do
    post_login 'disable clipaging'
  end

  cfg :telnet do
    pre_logout 'logout'
  end

  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^[\r\n]|^\s\s\s/, ''
    cfg = cfg.gsub "Command: show config effective", ''
    cfg
  end

  cmd 'show config effective'
end
