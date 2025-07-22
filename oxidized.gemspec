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
  s.files             = %x(git ls-files -z).split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
  s.executables       = %w[oxidized]
  s.require_path      = 'lib'

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 3.1'

  # Gemspec strategy
  #
  # For dependency and optional dependencies, we try to set the minimal
  # dependency lower than the Ubuntu Noble or Debian Bookworm package version,
  # so that native packages can be used.
  # We limit the maximal version so that dependabot can warn about new versions
  # and we can test them before activating them in Oxidized.
  #
  # development dependencies are set to the latest minor version of a library
  # and updated after having tested them

  s.add_dependency 'asetus',               '~> 0.4'
  s.add_dependency 'bcrypt_pbkdf',         '~> 1.0'
  s.add_dependency 'ed25519',              '~> 1.2'
  s.add_dependency 'net-ftp',              '~> 0.2'
  s.add_dependency 'net-http-digest_auth', '~> 1.4'
  s.add_dependency 'net-scp',              '~> 4.1'
  s.add_dependency 'net-ssh',              '~> 7.3'
  s.add_dependency 'net-telnet',           '~> 0.2'
  s.add_dependency 'psych',                '~> 5.0'
  s.add_dependency 'rugged',               '~> 1.6'
  s.add_dependency 'semantic_logger',      '~> 4.16'
  s.add_dependency 'slop',                 '~> 4.6'
  s.add_dependency 'syslog',               '~> 0.3.0'
  s.add_dependency 'syslog_protocol',      '~> 0.9.2'

  s.add_development_dependency 'bundler',             '~> 2.2'
  # ruby-git 4.0 requests ruby >= 3.2, we stick to >= 3.1 (Ubuntu Noble/Debian Bookworm)
  s.add_development_dependency 'git',                 '>= 2.0', '< 3.2.0'
  s.add_development_dependency 'minitest',            '~> 5.25.4'
  s.add_development_dependency 'mocha',               '~> 2.1'
  s.add_development_dependency 'pry',                 '~> 0.15.0'
  s.add_development_dependency 'rake',                '~> 13.0'
  s.add_development_dependency 'rubocop',             '~> 1.78.0'
  s.add_development_dependency 'rubocop-minitest',    '~> 0.38.0'
  s.add_development_dependency 'rubocop-rake',        '~> 0.7.0'
  s.add_development_dependency 'rubocop-sequel',      '~> 0.4.0'
  s.add_development_dependency 'simplecov',           '~> 0.22.0'

  # Dependencies on optional libraries, used for unit tests & development
  s.add_development_dependency 'oxidized-web',        '~> 0.16'
  s.add_development_dependency 'sequel',              '>= 5.63.0', '<= 5.94.0'
end
