class PurityOS < Oxidized::Model
  # Pure Storage Purity OS

  prompt /\w+@\S+(\s+\S+)*\s?>\s?$/
  comment '# '

  cmd 'pureconfig list'

  cfg :ssh do
    pty_options(term: "dumb")
    pre_logout 'exit'
  end
end
