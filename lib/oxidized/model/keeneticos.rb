class KeeneticOS < Oxidized::Model
  using Refinements

  prompt /\(config\)>/
  comment  '! '

  cmd :all do |cfg|
    cfg.gsub! /^!(.*)Last change:(.*)\n/, ''
    cfg.gsub! /^!(.*)Md5 checksum:(.*)\n/, ''
    cfg.gsub! /^!(.*)Username:(.*)\n/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( +password nt).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( +password md5).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( +authentication wpa-psk ns3).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( +iapp key ns3).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( +preshared-key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^( +authtoken).*( !.*)/, '\\1 <configuration removed>\\2'
    cfg.gsub! /^(crypto ike key \w+ \w+)\s(\w+)\s(\w+)/, '\\1 <configuration removed> \\3'
    cfg
  end

  cmd 'show ssh fingerprint' do |cfg|
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
