class PanOS < Oxidized::Model

  # PaloAlto PAN-OS model #

  comment  '! '

  prompt /^[\w.\@:\(\)-]+>\s?$/

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-3].join
  end

  cmd 'show system info' do |cfg|
    cfg.gsub! /^(up)?time:\ .*\n/, ''
    comment cfg
  end

  cmd 'show config running' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login 'set cli pager off'
    pre_logout 'exit'
  end
end
