class CiscoNGA < Oxidized::Model
  comment '# '
  prompt /([\w.@-]+[#>]\s?)$/

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show configuration' do |cfg|
    cfg
  end

  cfg :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
