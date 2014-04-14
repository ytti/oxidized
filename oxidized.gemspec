Gem::Specification.new do |s|
  s.name              = 'oxidized'
  s.version           = '0.0.49'
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

  s.add_dependency 'net-ssh'
  s.add_dependency 'sqlite3'
  s.add_dependency 'grit'
  s.add_dependency 'sequel'
  s.add_dependency 'sinatra'
  s.add_dependency 'sinatra-contrib'
  s.add_dependency 'puma'
  s.add_dependency 'haml'
  s.add_dependency 'sass'
  s.add_dependency 'slop'

end
