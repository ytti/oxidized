# Dell N Series
class NSeries < Oxidized::Model
  # Dell N Series

  prompt /^([\w.@()-]+[#>]\s?)$/
  comment '! '

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config'

  cmd :all do |cfg|
    cfg.lines.to_a[2..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(username \S+ password (?:encrypted )?)\S+(.*)/, '\1<hidden>\2'
    cfg
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    pre_logout 'exit'
    pre_logout 'exit'
  end
end
