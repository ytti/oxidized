class SROS < Oxidized::Model
  # Alcatel Lucent Router

  comment '# '

  prompt /^([-\w.\/:?\[\]\(\)]+#\s?)$/

  cmd 'show port description' do |cfg|
    cfg.gsub! /^[=-]+$\n/, ''
    cfg.gsub! /^Port Id\s*Description\s*$\n/, ''
    cfg.gsub! /^Port Descriptions on Slot (\S+)\s*\n$/, ''
    comment "#{cfg}\n"
  end

  cmd 'admin display-config' do |cfg|
    cfg.gsub! /^# Generated[^\n$]*(\n|$)/, ''
    cfg.gsub! /^# Finished[^\n$]*(\n|$)/, ''
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cfg :ssh do
    post_login 'environment no more'
    pre_logout 'exit all'
    pre_logout 'logout'
  end

end