# FW Version 1.0b170217
# HW Version 1
# Multiple version of this switch (Hardware and Firmware) - Commands are not the same... Thanks to the engineers are thinking this logic for the NetAdmins...

class Planet8P2SHW1 < Oxidized::Model
  using Refinements

  prompt /^[^\r\n]+[>#]\s?$/

  expect /Press <Enter> to continue\.\.\./i do |data, re|
    send "\r"
    data.sub(re, '')
  end

  expect /--More--/ do |data, re|
   send ' '
   data.gsub(/--More--\r?\n?/, '')
  end

  expect /\e\[H\e\[J/ do |data, re|
    data.sub(re, '')
  end

cmd :all do |cfg|
  cfg.gsub!(/^show running-config\s*\r?\n/, '')
  cfg.sub!(/\n\S+[>#]\s*$/, '')
  cfg.gsub!(/--More--/, '')
  cfg.gsub!(/\e\[[0-9;]*[A-Za-z]/, '')
  cfg.gsub!(/\010/, '')
  cfg.gsub!(/\r/, '')
  cfg = cfg.lines.reject { |l| l.strip.empty? }.join
  cfg
end

  cfg :ssh do
    username /^Username:\s*$/i
    password /^Password:\s*$/i
    pre_logout 'exit'
  end

  cmd 'show running-config' do |cfg|
    cfg
  end
end
