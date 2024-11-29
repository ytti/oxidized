lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oxidized/version'

Gem::Specification.new do |s|
  s.name              = 'oxidized'
  s.version           = Oxidized::VERSION
  s.licenses          = %w[Apache-2.0]
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Saku Ytti', 'Samer Abdel-Hafez', 'Anton Aksola']
  s.email             = %w[saku@ytti.fi sam@arahant.net aakso@iki.fi]
  s.homepage          = 'http://github.com/ytti/oxidized'
  s.summary           = 'feeble attempt at rancid'
  s.description       = 'software to fetch configuration from network devices and store them'
  s.rubyforge_project = s.name
  s.files             = %x(git ls-files -z).split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
  s.executables       = %w[oxidized]
  s.require_path      = 'lib'

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 3.1'

  s.add_dependency 'asetus',               '~> 0.1'
  s.add_dependency 'bcrypt_pbkdf',         '~> 1.0'
  s.add_dependency 'ed25519',              '~> 1.2'
  s.add_dependency 'net-ftp',              '~> 0.2'
  s.add_dependency 'net-http-digest_auth', '~> 1.4'
  s.add_dependency 'net-scp',              '~> 4.0'
  s.add_dependency 'net-ssh',              '~> 7.3'
  s.add_dependency 'net-telnet',           '~> 0.2'
  s.add_dependency 'psych',                '~> 5.0'
  s.add_dependency 'rugged',               '~> 1.6'
  s.add_dependency 'slop',                 '~> 4.6'

  s.add_development_dependency 'bundler',             '~> 2.2'
  s.add_development_dependency 'git',                 '~> 2'
  s.add_development_dependency 'minitest',            '~> 5.18'
  s.add_development_dependency 'mocha',               '~> 2.1'
  s.add_development_dependency 'pry',                 '~> 0.14.2'
  s.add_development_dependency 'rake',                '~> 13.0'
  s.add_development_dependency 'rubocop',             '~> 1.69.0'
  s.add_development_dependency 'rubocop-minitest',    '~> 0.36.0'
  s.add_development_dependency 'rubocop-rake',        '~> 0.6.0'
  s.add_development_dependency 'rubocop-sequel',      '~> 0.3.3'
  s.add_development_dependency 'simplecov',           '~> 0.22.0'
  s.add_development_dependency 'simplecov-cobertura', '~> 2.1.0'
  s.add_development_dependency 'simplecov-html',      '~> 0.13.1'

  # Dependencies on optional libraries, used for unit tests & development
  s.add_development_dependency 'oxidized-web',        '>= 0.14.0'
  s.add_development_dependency 'sequel',              '~> 5.63'
end
