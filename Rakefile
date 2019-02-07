require 'bundler/gem_tasks'
require 'rake/testtask'
require_relative 'lib/oxidized/version'

gemspec = eval(File.read(Dir['*.gemspec'].first))
file    = [gemspec.name, gemspec.version].join('-') + '.gem'

# Integrate Rubocop if available
begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
  task(:default).prerequisites << task(:rubocop)
rescue LoadError
  task :rubocop do
    puts 'Install rubocop to run its rake tasks'
  end
end

desc 'Validate gemspec'
task :gemspec do
  gemspec.validate
end

desc 'Run minitest'
task :test do
  Rake::TestTask.new do |t|
    t.libs << 'spec'
    t.test_files = FileList['spec/**/*_spec.rb']
    t.warning = true
    t.verbose = true
  end
end

task build: :version_set
task :version_set do
  Oxidized.version_set
  Bundler::GemHelper.instance.gemspec.version = Oxidized::VERSION
end

## desc 'Install gem'
## task :install => :build do
##   system "sudo -Es sh -c \'umask 022; gem install gems/#{file}\'"
## end

desc 'Remove gems'
task :clean do
  FileUtils.rm_rf 'pkg'
end

desc 'Tag the release'
task :tag do
  system "git tag #{gemspec.version}"
end

desc 'Push to rubygems'
task push: :tag do
  system "gem push pkg/#{file}"
end

task default: :test
