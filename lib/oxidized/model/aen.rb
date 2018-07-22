class AEN < Oxidized::Model
  # Accedian

  comment '# '

  prompt /^([-\w.\/:?\[\]()]+:\s?)$/

  cmd 'configuration generate-script module all' do |cfg|
    cfg
  end

  cmd :all do |cfg|
    cfg.cut_both
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
