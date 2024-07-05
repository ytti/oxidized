class RGOS < Oxidized::Model
  using Refinements

  comment '! '

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)?( \d)?) .+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^System start time/ }.join
    cfg = cfg.each_line.reject { |line| line.match /^\s*System uptime/ }.join
    comment "#{cfg.cut_both}\n"
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^Building configuration.../ }.join
    cfg = cfg.each_line.reject { |line| line.match /^Current configuration : \d+ bytes/ }.join
    cfg = cfg.each_line.reject { |line| line.match /^version [\d\w()]+/ }.join
    # remove empty lines
    cfg = cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
    cfg.cut_both
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
  end
end
