class EnterpriseSonic < Oxidized::Model
  using Refinements

  # Remove ANSI escape codes
  expect /\e\[[0-?]*[ -\/]*[@-~]\r?/ do |data, re|
    data.gsub re, ''
  end

  # Matches both sonic-cli and linux terminal
  prompt /^(?:[\w.-]+@[\w.-]+:[~\w\/-]+\$|[\w.-]+#)\s*/
  comment "# "

  cmd 'show running-configuration | no-more' do |cfg|
    comment cfg
  end

  cmd 'show version | no-more' do |cfg|
    cfg = cfg.each_line.grep(/Software Version|Product|Distribution|Kernel|Config DB Version|Build Commit|Platform|HwSKU|ASIC|Hardware Version|Serial Number|Mfg/).join
    comment cfg
  end

  cfg :ssh do
    post_login do
      cmd "sonic-cli"
    end
    pre_logout 'exit'
  end
end
