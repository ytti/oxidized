class Rad < Oxidized::Model
  prompt /([\w.@()*-]+[#>]\s?)$/
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

#  cmd :secret do |cfg|
#    cfg.gsub! /^(snmp set-read-community ").*+?(".*)$/, '\\1<secret hidden>\\2'
#    cfg
#  end
  
  cmd "show config system system-date" do |cfg|
    cfg
  end

  cmd "configure" do |cfg|
    cfg
  end

  cmd "terminal length 0" do |cfg|
    cfg
  end

  cmd "info" do |cfg|
    cfg
  end

  cfg :telnet, :ssh do
    post_login 'echo info'
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable"
        cmd vars(:enable)
     end
    end
    pre_logout "logout\r"
  end
end
