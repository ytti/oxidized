class PurityOS < Oxidized::Model
  using Refinements

  # Pure Storage Purity OS

  prompt /\w+@\S+(\s+\S+)*\s?>\s?$/
  comment '# '

  cmd 'pureconfig list' do |cfg|
    cfg.gsub! /^purealert flag \d+$/, ''
    cfg.gsub! /(.*VEEAM-StorageLUNSnap-[0-9a-f].*)/, ''
    cfg.gsub! /(.*VEEAM-ExportLUNSnap-[0-9A-F].*)/, ''
    # remove empty lines
    cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
  end

  cfg :ssh do
    pty_options(term: "dumb")
    pre_logout 'exit'
  end
end
