Gem::Specification.new do |s|
  s.name              = 'oxidized'
  s.version           = '0.0.1'
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti' ]
  s.email             = %w( saku@ytti.fi )
  s.summary           = 'feeble attempt at rancid'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.require_path      = 'lib'
end
