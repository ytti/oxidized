class Vyos < Oxidized::Model
  using Refinements

  # VyOS model #
  # Vyos is a Fork of Vyatta and is being actively developed.
  # https://vyos.org/

  prompt /^\S+@\S+(:~\$|>) $/
  clean :escape_codes

  cmd :all do |cfg|
    cfg.lines.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /secret (\S+).*/, 'secret <secret removed>'
    cfg.gsub! /password (\S+).*/, 'password <secret removed>'
    cfg.gsub! /community (\S+)/, 'community <secret removed>'
    cfg.gsub! /preshared-key (\S+).*/, 'preshared-key <secret removed>'
    cfg.gsub! /private key (\S+).*/, 'private key <secret removed>'
    cfg.gsub! /private-key (\S+).*/, 'private-key <secret removed>'
    # password in URLs like protocol://user:password@domain.tld/
    cfg.gsub! /([a-z]+:\/\/[^:\s]+:)\S+@/, '\1<secret removed>@'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show configuration commands | no-more'

  cfg :ssh do
    pre_logout 'exit'
  end
end
