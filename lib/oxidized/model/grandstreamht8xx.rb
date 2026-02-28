class GrandstreamHT8xx < Oxidized::Model
  using Refinements

  # Anchored prompt to avoid matching XML content
  prompt /^(GS|CONFIG)>\s?$/
  comment '# '

  cfg :ssh do
    # After login go to configuration submenu (looks like enabled in other devices)
    post_login 'config'
    # When logout use double exit - first from configuration submenu, and second to disconnect from device
    pre_logout 'exit'
    pre_logout 'exit'
  end

  cmd 'export' do |cfg|
    cfg.lines[1..-2]&.join
  end
end
