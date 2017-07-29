class Enterasys < Oxidized::Model

  # Enterasys B3 model #

  prompt /^.+\w\(su\)->\s?$/

  comment  '!'

  cmd :all do |cfg|
     cfg.each_line.to_a[1..-2].join
  end

  cmd 'show system hardware' do |cfg|
    cfg
  end

  cmd 'show config' do |cfg|
    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end
