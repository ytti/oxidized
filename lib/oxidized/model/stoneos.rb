class StoneOS < Oxidized::Model
  # Hillstone Networks StoneOS software

  prompt /^\r?[\w.()-]+[#>](\s)?$/
  comment '# '

  expect /^\s.*--More--.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show configuration running'

  cmd 'show version' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username(/^login:/)
    password(/^Password:/)
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 256'
    post_login 'terminal width 512'
    pre_logout 'exit'
  end
end
