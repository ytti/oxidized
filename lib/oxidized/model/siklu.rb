class Siklu < Oxidized::Model

  # Siklu EtherHaul #

  comment '# '

  prompt /^[\w-]+>$/

  cmd 'copy running-configuration display'

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end
