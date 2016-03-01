class NetScaler < Oxidized::Model

  prompt /^\>\s*$/
  comment '# '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show hardware' do |cfg|
    comment cfg
  end

  cmd 'show ns ns.conf'

  cfg :ssh do
    pre_logout 'exit'
  end

end
