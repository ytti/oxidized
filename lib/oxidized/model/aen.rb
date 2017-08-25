class AEN < Oxidized::Model
  # Accedian

  comment '# '

  prompt /^([-\w.\/:?\[\]\(\)]+:\s?)$/

  cmd 'configuration generate-script module all' do |cfg|
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end