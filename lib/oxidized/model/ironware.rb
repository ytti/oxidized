class IronWare < Oxidized::Model

  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show chassis' do |cfg|
    cfg.gsub! "\xFF", '' # ugly hack - avoids JSON.dump utf-8 breakage on 1.9..
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

end
