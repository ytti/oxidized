# model for Centec Networks CNOS based switches
class CNOS < Oxidized::Model
  using Refinements

  comment '! '

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)?( \d)?) .+/, '\\1 <secret hidden>'
    cfg
  end

  cmd :all do |cfg|
    cfg = cfg.delete("\r")
    cfg.cut_both
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /\ uptime\ is\ / }.join
    comment cfg
  end

  cmd 'show transceiver' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    # remove empty lines
    cfg = cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
    cfg
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
