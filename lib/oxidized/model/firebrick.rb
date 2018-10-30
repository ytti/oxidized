class Firebrick < Oxidized::Model
  # Firebrick #
  prompt /\x0a\x1b\x5b\x32\x4b\x0d.*>\s/

  cmd :all do |cfg|
    # sometimes ironware inserts arbitrary whitespace after commands are
    # issued on the CLI, from run to run.  this normalises the output.
    cfg.each_line.to_a[1..-2].drop_while { |e| e.match /^\s+$/ }.join
  end

  cmd 'show status' do |cfg|
    cfg.gsub! /Status/, ''
    cfg.gsub! /------/, ''
    cfg.gsub! /Uptime.*/, ''
    cfg.gsub! /Current time.*/, ''
    cfg.gsub! /RAM.*/, ''
    cfg.gsub! /Warranty.*/, ''

    comment cfg
  end

  cmd 'show configuration'

  cfg :telnet do
    username /Username:\s?/
    password /Password:\s?/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
