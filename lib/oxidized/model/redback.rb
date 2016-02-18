class Redback < Oxidized::Model
  prompt /^([\[\]\w.@-]+[#>]\s?)$/
  # Ericsson Redback

  cmd 'show chassis'
  cmd 'show hardware detail'
  cmd 'show release'
  cmd 'show config'

  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'n'
  end

end

