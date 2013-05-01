class IOS < Oxidized::Model

  comment  '! '

  # example how to handle pager
  #expect /^\s--More--\s+.*$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  #end

  # non-preferred way to handle additional PW prompt
  #expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send CFG.passwords[:enable] + "\n"
  #  data
  #end

  cmd :all do |cfg|
    #cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    #cfg.gsub! /\cH+/, ''              # example how to handle pager
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.sub! /^(ntp clock-period).*/, '! \1'
    cfg
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    # preferred way to handle additional passwords
    #post_login do
    #  send "enable\n"
    #  send CFG.passwords[:enable] + "\n"
    #end
    pre_logout 'exit'
  end

end
