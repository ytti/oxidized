class HpeMsa < Oxidized::Model
  prompt /^#\s?$/

  cmd 'show configuration'

  cfg :ssh do
    post_login 'set cli-parameters pager disabled'
    pre_logout 'exit'
  end
end
