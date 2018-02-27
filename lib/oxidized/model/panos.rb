class PanOS < Oxidized::Model

  # PaloAlto PAN-OS model #

  comment  '! '

  prompt /^[\w.\@:\(\)-]+[>#]\s?$/

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-3].join
  end

  cmd 'show system info' do |cfg|
    cfg.gsub! /^(up)?time:\ .*$/, ''
    cfg.gsub! /^app-.*?:\ .*$/, ''
    cfg.gsub! /^av-.*?:\ .*$/, ''
    cfg.gsub! /^threat-.*?:\ .*$/, ''
    cfg.gsub! /^wildfire-.*?:\ .*$/, ''
    cfg.gsub! /^wf-private.*?:\ .*$/, ''
    cfg.gsub! /^url-filtering.*?:\ .*$/, ''
    cfg.gsub! /^global-.*?:\ .*$/, ''
    comment cfg
  end

  cmd 'configure'

  cmd 'show' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login 'set cli pager off'
    if vars :panos_config_format
      post_login 'set cli config-output-format ' + vars(:panos_config_format)
    end
    pre_logout 'quit'
    pre_logout 'quit'
  end
end
