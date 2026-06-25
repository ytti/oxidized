class PanoramaSet < Oxidized::Model

  comment '! '

  prompt /^[\w.@:()-]+[#>]\s?$/

  cmd 'show' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login 'set cli pager off'
    post_login 'set cli config-output-format set'
    post_login 'configure'
    pre_logout 'exit'
    pre_logout 'quit'
  end
end
