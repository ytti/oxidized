class Vyatta < Oxidized::Model
  # Brocade Vyatta / VyOS model #

  prompt /@.*?:~\$\s/

  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /encrypted-password (\S+).*/, 'encrypted-password <secret removed>'
    cfg.gsub! /plaintext-password (\S+).*/, 'plaintext-password <secret removed>'
    cfg.gsub! /password (\S+).*/, 'password <secret removed>'
    cfg.gsub! /pre-shared-secret (\S+).*/, 'pre-shared-secret <secret removed>'
    cfg.gsub! /community (\S+) {/, 'community <hidden> {'
    cfg
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
