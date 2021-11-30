class NecIX < Oxidized::Model
  prompt /^(\([\w.-]*\)\s[#$]|^\S+[$#]\s?)$/
  comment '! '
  expect /^--More--$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-2].join
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
