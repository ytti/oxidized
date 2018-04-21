class Coriant8600 < Oxidized::Model
  comment '# '

  prompt /^[^\s#>]+[#>]$/

  cmd 'show hw-inventory' do |cfg|
    comment cfg
  end

  cmd 'show flash' do |cfg|
    comment cfg
  end

  cmd 'show run' do |cfg|
    cfg
  end

  cfg :telnet do
    username /^user name:$/
    password /^password:$/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
    post_login 'enable'
    post_login 'terminal more off'
  end
end
