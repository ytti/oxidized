class PurityOS < Oxidized::Model
  # Pure Storage Purity OS

  prompt /\w+@\S+(\s+\S+)*\s?>\s?$/
  comment '# '

  cmd 'pureconfig list'

  cfg :ssh do
    pre_logout 'exit'
  end
end
