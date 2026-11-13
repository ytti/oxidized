class NecIX < Oxidized::Model
  using Refinements

  prompt /^(\([\w.-]*\)\s[#$]|^\S+[$#]\s?)$/
  comment '! '
  expect /^--More--$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.cut_both(3)
    cfg.gsub! /^.*Current time.*$/, ''
    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login do
      send "configure\n"
    end

    pre_logout do
      send "\cZ"
      send "exit\n"
    end
  end
end
