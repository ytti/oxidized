class IronWare < Oxidized::Model

  prompt /^.+[>#]\s?$/
  comment  '! '
  
  #to handle pager without enable
  #expect /^((.*)--More--(.*))$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  #end

  
  #to remove backspace (if handle pager without enable)
  #expect /^((.*)[\b](.*))$/ do |data, re|
  #  data.sub re, ''
  #end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /(^((.*)uptime(.*))$)/, '' #remove unwanted line system uptime
    comment cfg
  end
  
  cmd 'show flash' do |cfg|
    comment cfg
  end
  
  cmd 'show module' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  #handle pager with enable
  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    post_login 'skip-page-display'
    post_login 'terminal length 0'
    pre_logout 'logout'
    pre_logout 'exit'
    pre_logout 'exit'
  end

end