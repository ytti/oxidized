class TELCO < Oxidized::Model
  # Telco Systems T-Marc 3306

  prompt /^(\r?[\w.@_()-]+[#]\s?)$/
  comment '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].join.delete("\n")
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end
end
