class Edgeos < Oxidized::Model
  using Refinements

  # Ubiquiti EdgeOS #

  prompt /@.*?:~\$\s/

  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub!(/(encrypted-password) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(plaintext-password) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(password) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(pre-shared-secret) \S+/, '\1 <secret removed>')
    cfg.gsub!(/(community) \S+ {/, '\1 <hidden> {')
    cfg.gsub!(/(commit-archive location) \S+/, '\1 <secret removed>')
    cfg
  end

  cmd 'show version | no-more' do |cfg|
    cfg.gsub! /^Uptime:\s.+/, ''
    comment cfg
  end

  cmd 'show configuration commands | no-more'

  cfg :telnet do
    username  /login:\s/
    password  /^Password:\s/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
