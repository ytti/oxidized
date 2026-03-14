class CiscoNGA < Oxidized::Model
  using Refinements

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
