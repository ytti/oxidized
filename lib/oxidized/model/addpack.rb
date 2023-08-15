class AddPack < Oxidized::Model
  using Refinements
  PROMPT = /^.*[>#]\s?$/

  # Used in AddPack Voip, such as AP100_G2

  prompt PROMPT
  cmd 'enable'

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Building configuration.../, ''
    cfg.gsub! /^*show running-config/, ''
    cfg.gsub! PROMPT, ''
    expect '\s--More--\s' do
      send ' '
    end
    cfg
  end

  cfg :telnet do
    username /^Login:/i
    password /^Password:/i
  end
end
