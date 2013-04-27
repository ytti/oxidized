class PowerConnect < Oxidized::Model

  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1].join
    cfg
  end

  cfg :telnet do
    username /^User Name:/
    password /^\r?Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal datadump'
    pre_logout 'exit'
  end

end
