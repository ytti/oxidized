class ML66 < Oxidized::Model
  comment '! '
  prompt /.*#/

  expect /User:.*$/ do |data, re|
    send "admin_user\n"
    send "#{@node.auth[:password]}\n"
    data.sub re, ''
  end

  cmd 'show version' do |cfg|
    cfg.gsub! "Uptime", ''
    comment cfg
  end

  cmd 'show inventory hw all' do |cfg|
    comment cfg
  end

  cmd 'show inventory sw all' do |cfg|
    comment cfg
  end

  cmd 'show license status all' do |cfg|
    comment cfg
  end

  cmd 'show running-config'

  cfg :ssh do
    pre_logout 'logout'
  end
end
