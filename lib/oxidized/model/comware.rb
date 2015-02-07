class Comware < Oxidized::Model
  # HP (A-series)/H3C/3Com Comware
  
  prompt /^(<[\w.-]+>)$/
  comment '# '

  # example how to handle pager
  #expect /^\s*---- More ----$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  #end

  cmd :all do |cfg|
    #cfg.gsub! /^.*\e\[42D/, ''        # example how to handle pager
    cfg.each_line.to_a[1..-2].join
  end
 
  cfg :telnet do
    username /^Username:$/
    password /^Password:$/
  end

  cfg :telnet, :ssh do
    post_login 'screen-length disable'
    post_login 'undo terminal monitor'
    pre_logout 'quit'
  end

  cmd 'display version' do |cfg|
    cfg = cfg.each_line.select {|l| not l.match /uptime/ }.join
    comment cfg
  end

  cmd 'display device' do |cfg|
    comment cfg
  end

  cmd 'display current-configuration' do |cfg|
    cfg
  end
end
