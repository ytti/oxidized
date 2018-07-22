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
  s.files             = %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.executables       = %w[oxidized]
  s.require_path      = 'lib'

  s.required_ruby_version =           '>= 2.0.0'
  s.add_runtime_dependency 'asetus',  '~> 0.1'
  s.add_runtime_dependency 'net-ssh', '~> 4.1.0'
  s.add_runtime_dependency 'rugged',  '~> 0.21', '>= 0.21.4'
  s.add_runtime_dependency 'slop',    '~> 3.5'

  if defined?(RUBY_VERSION) && RUBY_VERSION > '2.3'
    s.add_runtime_dependency 'net-telnet', '~> 0'
  end

  s.add_development_dependency 'simplecov'
  if ENV['CI'] == 'true'
    s.add_development_dependency 'codecov'
  end

  s.add_development_dependency 'bundler',  '~> 1.10'
  s.add_development_dependency 'git',      '~> 1'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'mocha',    '~> 1.1'
  s.add_development_dependency 'pry',      '~> 0'
  s.add_development_dependency 'rake',     '~> 10.0'
  s.add_development_dependency 'rubocop',  '~> 0.57.1'
end
