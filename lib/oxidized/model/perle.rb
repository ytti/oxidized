class Perle < Oxidized::Model
  using Refinements

  prompt /^[\w.-]+#/
  comment '! '

  cmd :all do |cfg|
    cfg.cut_both
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

  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
