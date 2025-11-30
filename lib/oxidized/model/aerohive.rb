class Aerohive < Oxidized::Model
  prompt /(\([\w.@()-]+\)\s[#>]\s?)$/

  cmd 'enable'

  cmd 'terminal length 0'

  cmd 'show running-config' do |cfg|
    # Remove o próprio comando da saída
    cfg.gsub! /^show running-config/, ''

    cfg.gsub! /^!System Up Time .+$/, ''
    cfg.gsub! /^!Current SNTP Synchronized Time: .+$/, ''

    cfg
  end

  cfg :ssh do
  end
end
