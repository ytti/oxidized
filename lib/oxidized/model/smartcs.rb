class SmartCS < Oxidized::Model

  prompt /^\r?([\w.@() -]+[#>]\s?)$/
  comment '# '

  cmd :all do |cfg|
    cfg.cut_both
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show config' do |cfg|
    cfg
  end

  cfg :telnet do
    username(/^login:/)
    password(/^Password:/)
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "su\n"
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
  end
end
