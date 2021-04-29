class Mediant < Oxidized::Model

  comment  '# '

  # handle pager
  expect /^\s--MORE--.*$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  # remove backspace 
  expect /^((.*)[\b](.*))$/ do |data, re|
    data.gsub! /[\b]+/, ''
    data.gsub! /^[\ ]{9}/, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd "show system version| include ;\r\n" do |cfg|
    comment cfg
  end

  cmd "show system assembly\r\n" do |cfg|
    comment cfg
  end

  cmd "show running-config\r\n" do |cfg|
    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\r\n"
        cmd vars(:enable)+"\r\n"
      end
    end
    pre_logout 'exit'+"\r\n"
  end

end

