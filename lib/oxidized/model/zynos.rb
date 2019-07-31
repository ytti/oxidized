class ZyNOS < Oxidized::Model
  # Used in Zyxel GS1900 switches
  # Used in Zyxel DSLAMs, such as SAM1316, please comment out prompt line for those

  prompt /^.*# $/
  comment '! '

  expect /^--More--$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd 'config-0'

  cmd 'show running-config' do |cfg|
    cfg.gsub! /(System Up Time:) \S+(.*)/, '\\1 <time>'
    
    # Remove garbage chars sent when by --More--
    # Backspace 0x07 char
    cfg.gsub! /[\b]/, ''
    cfg.gsub! /\e\[A\e\[2K/, ''
    
    cfg
  end
  
  cfg :ftp do
  end

  cfg :telnet, :ssh do
    username /^(User name|.*Username):/
    password /^\r?Password:/
  end

  cfg :telnet do
    pre_logout do
      send "exit\r"
    end
  end

  cfg :ssh do
    pre_logout do
      # Yes, that GS1900 switch needs two exit !
      send "exit\n"
      send "exit\n"
    end
  end
end
