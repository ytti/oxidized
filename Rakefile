require 'bundler/gem_tasks'
require 'rake/testtask'

gemspec = eval(File.read(Dir['*.gemspec'].first))
file    = [gemspec.name, gemspec.version].join('-') + '.gem'

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

desc 'Build gem'
task :build do
  system "gem build #{gemspec.name}.gemspec"
  FileUtils.mkdir_p 'gems'
  FileUtils.mv file, 'gems'
end

desc 'Install gem'
task :install => :build do
  system "sudo -Es sh -c \'umask 022; gem install gems/#{file}\'"
end

desc 'Remove gems'
task :clean do
  FileUtils.rm_rf 'gems'
end

desc 'Tag the release'
task :tag do
  system "git tag #{gemspec.version}"
end

desc 'Push to rubygems'
task :push => :tag do
  system "gem push gems/#{file}"
end

task default: :test
