class Hirschmann < Oxidized::Model
  prompt /^[(\w\s)]+\s[>|#]+?$/

  comment '## '

  # Handle pager
  expect /^--More--.*$/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show sysinfo' do |cfg|
    cfg.gsub! /^System Up Time.*\n/, ""
    cfg.gsub! /^System Date and Time.*\n/, ""
    cfg.gsub! /^CPU Utilization.*\n/, ""
    cfg.gsub! /^Memory.*\n/, ""
    cfg.gsub! /^Average CPU Utilization.*\n/, ""
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^users.*\n/, ""
    cfg
  end

  cfg :telnet do
    username /^User:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    pre_logout 'logout'
  end
end
