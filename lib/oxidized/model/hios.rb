class Hios < Oxidized::Model
  ## Docker location: /var/lib/gems/2.7.0/gems/oxidized-0.28.0/lib/oxidized/model/hios.rb
  prompt /^\[[\w\s\W]+\][>|#]+?$/

  comment '## '

  # Handle pager
  expect /^--More--.*$/ do |data, re|
    send 'n'
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show system info' do |cfg|
    cfg.gsub! /^System uptime.*\n/, ""
    cfg.gsub! /^Operating hours.*\n/, ""
    cfg.gsub! /^System date.*\n/, ""
    cfg.gsub! /^Current temperature.*\n/, ""
    comment cfg
  end

  cmd 'show running-config script' do |cfg|
    ## User creds are not shown with the command above
    #cfg.gsub! /^users.*\n/, ""
    cfg
  end

  cfg :telnet do
    username /^User:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'enable'
    pre_logout "logout\nY\r\n"
  end
end
