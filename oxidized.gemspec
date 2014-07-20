Gem::Specification.new do |s|
  s.name              = 'oxidized'
  s.version           = '0.1.0'
  s.licenses          = ['Apache-2.0']
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti' ]
  s.email             = %w( saku@ytti.fi )
  s.homepage          = 'http://github.com/ytti/oxidized'
  s.summary           = 'feeble attempt at rancid'
  s.description       = 'software to fetch configuration from network devices and store them'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( oxidized )
  s.require_path      = 'lib'

  s.required_ruby_version =   '>= 1.9.3'
  s.add_dependency 'asetus',  '~> 0.1'
  s.add_dependency 'slop',    '~> 3.5'
  s.add_dependency 'net-ssh', '~> 2.8'
end
