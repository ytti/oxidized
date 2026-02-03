class Perle < Oxidized::Model
  using Refinements

  prompt /^[\w.-]+#/
  comment '! '

  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg.delete "\r"
  end

  cmd 'show version verbose' do |cfg|
    comment cfg
  end

  cmd 'show system hardware' do |cfg|
    comment cfg + "\n"
  end

  cmd 'show interfaces transceiver' do |cfg|
    cfg = cfg.keep_lines [
      'SFP Information',
      'Vendor Name',
      'Vendor Serial Number'
    ]
    comment cfg + "\n"
  end

  cmd 'show running-config'

  cmd :significant_changes do |cfg|
    cfg.reject_lines [
      /^tacacs-server key 7 \$0\$\S+==$/
    ]
  end

  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
