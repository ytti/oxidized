class Vyos < Oxidized::Model
  using Refinements

  # VyOS model #
  # Vyos is a Fork of Vyatta and is being actively developed.
  # https://vyos.org/

  prompt /@.*(:~\$|>)\s/

  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /secret (\S+).*/, 'secret <secret removed>'
    cfg.gsub! /password (\S+).*/, 'password <secret removed>'
    cfg.gsub! /community (\S+)/, 'community <secret removed>'
    cfg.gsub! /key (\S+).*/, 'key <secret removed>'
    cfg
  end

  # No idea where the extra characters come from.
  # But the gsub removes them
  cmd 'show version' do |cfg|
    cfg.gsub! /\e\S*\r*/, ''
    comment cfg
  end

  cmd 'show configuration commands | no-more'

  cfg :ssh do
    pre_logout 'exit'
  end
end
