class Icotera < Oxidized::Model
  comment '## '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show management' do |cfg|
    cfg.gsub! /^\s+System uptime.*\n/, ""
    cfg.gsub! /^\s+Bytes in.*\n/, ""
    cfg.gsub! /^\s+Pkts in.*\n/, ""
    cfg.gsub! /^\s+Ucast in.*\n/, ""
    cfg.gsub! /^\s+Bcast in.*\n/, ""
    cfg.gsub! /^\s+Mcast in.*\n/, ""
    cfg.gsub! /^\s+Ucast in pps.*\n/, ""
    cfg.gsub! /^\s+Mcast in pps.*\n/, ""
    cfg.gsub! /^\s+Total in bps.*\n/, ""

    comment cfg
  end

  cmd 'copy progress screen'

  cfg :ssh do
    pre_logout 'exit'
  end
end
