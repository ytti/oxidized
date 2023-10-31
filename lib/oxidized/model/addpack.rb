class AddPack < Oxidized::Model
  # Used in AddPack Voip, such as AP100B, AP100_G2, AP700, AP1000, AP1100F

  using Refinements
  PROMPT = /^.*[>#]\s?$/

  expect /-- [Mm]ore --/ do |data, re|
    send ' '
    data.sub re, ''
  end

  prompt PROMPT
  cmd 'enable'

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Building configuration.../, ''
    cfg.gsub! /^*show running-config/, ''
    cfg.gsub! PROMPT, ''
    cfg
  end

  cfg :telnet do
    username /[Ll]ogin:\s?/
    password /[Pp]assword:\s?/
  end
end
