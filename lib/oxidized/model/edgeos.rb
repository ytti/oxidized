class Edgeos < Oxidized::Model

  # EdgeOS #

  prompt /\@.*?\:~\$\s/

  cmd :all do |cfg|
    cfg = cfg.lines.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /community (\S+) {/, 'community <hidden> {'
    cfg
  end

  cmd 'show configuration | no-more'

  cfg :telnet do
    username  /login:\s/
    password  /^Password:\s/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end

end
