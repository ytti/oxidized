class OpnSense < Oxidized::Model
  # minimum required permissions: "System: Shell account access"
  # must enable SSH and password-based SSH access

  cmd :all do |cfg|
    cfg.cut_head
  end

  cmd 'cat /conf/config.xml' do |cfg|
    cfg.gsub! /\s<revision>\s*<time>\d*<\/time>\s*.*\s*.*\s*<\/revision>/, ''
    cfg.gsub! /\s<last_rule_upd_time>\d*<\/last_rule_upd_time>/, ''
    cfg
  end

  cfg :ssh do
    exec true
    pre_logout 'exit'
  end
end
