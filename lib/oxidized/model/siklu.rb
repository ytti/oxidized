class Siklu < Oxidized::Model
  using Refinements

  # Siklu EtherHaul #

  prompt /^[\^M\s]{0,}[\w\-\s."()]+>$/

  cmd 'copy startup-configuration display' do |cfg|
    cfg.each_line.to_a[2..2].join
  end

  cmd 'copy running-configuration display' do |cfg|
    cfg.cut_both(3)
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
