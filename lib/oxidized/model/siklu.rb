class Siklu < Oxidized::Model

  # Siklu EtherHaul #

  prompt /^[\w-]+>$/

  cmd 'copy startup-configuration display' do |cfg|
    cfg.each_line.to_a[2..2].join
  end

  cmd 'copy running-configuration display' do |cfg|
    cfg.each_line.to_a[3..-2].join
  end

  cfg :ssh do
    pre_logout 'exit'
  end

end
