class OneOS < Oxidized::Model
  prompt /^([\w.@()-]+#\s?)$/
  comment  '! '

  # example how to handle pager
  # expect /^\s--More--\s+.*$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  # non-preferred way to handle additional PW prompt
  # expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  # end

  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    # cfg.gsub! /\cH+/, ''              # example how to handle pager
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp set-read-community ").*+?(".*)$/, '\\1<secret hidden>\\2'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system hardware' do |cfg|
    comment cfg
  end

  cmd 'show product-info-area' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[0..-1].join
    cfg.gsub! /^Building configuration...\s*[^\n]*\n/, ''
    cfg.gsub! /^Current configuration :\s*[^\n]*\n/, ''
    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'term len 0'
    pre_logout 'exit'
  end
end
