class Apc_aos < Oxidized::Model

  cmd 'config.ini' do |cfg|
    cfg.gsub! /^; Configuration file\, generated on.*/, ''
  end

  cfg :ftp do
  end

end

