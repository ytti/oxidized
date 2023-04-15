class SmartCS < Oxidized::Model
  prompt /^\r?([\w.@() -]+[#>]\s?)$/
  comment '# '

  expect /-more <Press SPACE for another page, 'q' to quit>-/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg.insert(0, "--------------------------------------------------------------------------------! \n")
    # Unhash below to write a comment in the config file.
    cfg.insert(0, "Starting: show version cmd \n")
    cfg << "\n \nEnding: show version cmd"
    comment cfg << "\n--------------------------------------------------------------------------------! \n \n"
    comment cfg
  end

  cmd 'show config' do |cfg|
    # remove "Press SPACE for another page" add SPACE(\s)
    cfg.gsub! /\s{5,}/, ""
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    post_login do
      pw = vars(:enable)
      pw ||= ""
      send "su\r"
      expect /[pP]assword:\s?$/
      cmd pw
    end
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
