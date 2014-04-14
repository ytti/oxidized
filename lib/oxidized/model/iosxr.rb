class IOSXR < Oxidized::Model

  # IOS XR model #

  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].join
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show platform' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    if CFG.vars.enable?
      post_login do
        send "enable\n"
        send CFG.vars.enable + "\n"
      end
    end
    pre_logout 'exit'
  end

end
