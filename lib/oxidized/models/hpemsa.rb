class HpeMsa < Oxidized::Model
  using Refinements

  prompt /^#\s?$/

  cmd 'show configuration'

  cfg :ssh do
    post_login 'set cli-parameters pager disabled'
    pre_logout 'exit'
  end
end
