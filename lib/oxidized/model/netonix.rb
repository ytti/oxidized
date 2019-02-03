class Netonix < Oxidized::Model
  prompt /^[\w\s\(\).@_\/:-]+#/

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'cat config.json;echo'

  cfg :ssh do
    post_login 'cmdline'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
