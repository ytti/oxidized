Gem::Specification.new do |s|
  s.name              = 'oxidized'
  s.version           = '0.3.0'
  s.licenses          = %w( Apache-2.0 )
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti', 'Samer Abdel-Hafez' ]
  s.email             = %w( saku@ytti.fi sam@arahant.net )
  s.homepage          = 'http://github.com/ytti/oxidized'
  s.summary           = 'feeble attempt at rancid'
  s.description       = 'software to fetch configuration from network devices and store them'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( oxidized )
  s.require_path      = 'lib'

  s.required_ruby_version =           '>= 1.9.3'
  s.add_runtime_dependency 'asetus',  '~> 0.1'
  s.add_runtime_dependency 'slop',    '~> 3.5'
  s.add_runtime_dependency 'net-ssh', '~> 2.8'
  s.add_runtime_dependency 'rugged',  '~> 0.21.4'
end
