class PanOS < Oxidized::Model
  using Refinements

  # PaloAlto PAN-OS model #

  comment '! '

  prompt /^[\w.@:()-]+>\s?$/

  cmd :all do |cfg|
    cfg.cut_both(2, 2)
  end

  cmd 'show system info' do |cfg|
    cfg.gsub! /^(up)?time: .*$/, ''
    cfg.gsub! /^app-.*?: .*$/, ''
    cfg.gsub! /^av-.*?: .*$/, ''
    cfg.gsub! /^threat-.*?: .*$/, ''
    cfg.gsub! /^wildfire-.*?: .*$/, ''
    cfg.gsub! /^wf-private.*?: .*$/, ''
    cfg.gsub! /^device-dictionary-version.*?: .*$/, ''
    cfg.gsub! /^device-dictionary-release-date.*?: .*$/, ''
    cfg.gsub! /^url-filtering.*?: .*$/, ''
    cfg.gsub! /^global-.*?: .*$/, ''
    comment cfg
  end

  cmd 'show config running' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login 'set cli pager off'
    pre_logout 'quit'
  end
end
