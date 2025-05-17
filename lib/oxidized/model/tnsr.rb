class TNSR < Oxidized::Model
  using Refinements

  # Netgate TNSR #

  prompt /^.+[#]\s$/

  comment '! '

  expect /^--More--/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    # remove orphans \r
    cfg.gsub! /^\r+(.+)/, '\1'
    # handle pager orphans ^H^H^H^H^H^H^H^H        ^H^H^H^H^H^H^H^H
    cfg.gsub! /\x08{8}\x20{8}\x08{8}/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    # verified against tnsr
    cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp community community-name ).*/, '\\1 <configuration removed>'

    # not verified, taken from eos model for similarity
    cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (?:secret|password)).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server key \d+).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(radius-server .+ key \d) \S+/, '\\1 <radius secret hidden>'
    cfg.gsub! /( {6}key) (\h+ 7) (\h+).*/, '\\1 <secret hidden>'
    cfg.gsub! /(localized|auth (md5|sha\d{0,3})|priv (des|aes\d{0,3})) \S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version all' do |cfg|
    comment cfg
  end

  cmd 'show configuration running cli' do |cfg|
    cfg
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
