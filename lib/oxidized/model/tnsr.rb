class TNSR < Oxidized::Model
  using Refinements

  # Netgate TNSR #

  # prompt examples
  # https://docs.netgate.com/tnsr/en/latest/basics/working-cli.html#command-prompt
  #  "<hostname> tnsr<(mode)># " <-- with trailing whitespace
  #  tnsr-dev-25-02 tnsr#
  #  tnsr-dev-25-02 tnsr(config)#  <-- after "configure terminal", but this is not important for oxidized
  # prompt from debug log
  #  received "Welcome to Netgate TNSR Version: 25.02-2\r\n\r\n\t* Documentation:  https://docs.netgate.com/tnsr/en/latest/\r\n\t* Support:        https://www.netgate.com/support\r\n\r\n   _          __________\r\n _| |_ _ __  | ___ _ __ |\r\n|_  __| '_ \\ |/ __| '__||\r\n  | |_| | | ||\\__ \\ |   |\r\n   \\__|_| |_|||___/_|   |\r\n             |__________|\r\n\r\n\r\n"
  #  received "\r\nVersion: 25.02-2\r\n\r\nFor information see 'show documentation'\r\n\r\n"
  #  received "\rbgp01 tnsr# "
  # when the --More-- pager is the last line of paged output, the prompt contains \x08\x20\x08 orphans on the begin
  #  you can look for context into spec simulation:
  #    spec/model/data/tnsr:TNSR_24.10-3_short-config:simulation.yaml
  #    spec/model/data/tnsr:TNSR_25.02-2_long-config-and-pager-at-last-line:simulation.yaml
  prompt /^((\x08{8}\x20{8}\x08{8})?\r?[\w-]+\stnsr#\s?)$/

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
