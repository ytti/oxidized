class IPOS < Oxidized::Model

  # Ericsson SSR (IPOS)
  # Redback SE (SEOS)

  prompt /^([\[\]\w.@-]+[#>]\s?)$/
  comment '! '

  cmd 'show chassis' do |cfg|
    comment cfg
  end

  cmd 'show hardware detail' do |cfg|
    comment cfg
  end

  cmd 'show release' do |cfg|
    comment cfg
  end

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

