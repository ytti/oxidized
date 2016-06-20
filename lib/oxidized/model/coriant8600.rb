class Coriant8600 < Oxidized::Model

  prompt /^[^\s#]+[#>]/

  cmd 'show hw-inventory' do |cfg|
    comment cfg
  end

  cmd 'show flash' do |cfg|
    comment cfg
  end
  
  cmd 'show run' do |cfg|
    cfg
  end

  cfg :telnet, :ssh do
    username /^user name:$/
    password /^password:$/
    pre_logout 'exit'
    post_login 'enable'
    post_login 'terminal more off'
  end

end
