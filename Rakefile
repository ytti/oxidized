require 'bundler/gem_tasks'
require 'rake/testtask'
require_relative 'lib/oxidized/version'

gemspec = Gem::Specification.load(Dir['*.gemspec'].first)
gemfile = [gemspec.name, gemspec.version].join('-') + '.gem'

# Integrate Rubocop if available
begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
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
    t.ruby_opts = ['-W:deprecated']
    # Don't display ambiguity warning between regexp and division in models
    t.warning = false
    t.verbose = true
  end
end

task build: %i[chmod version_set]

desc 'Set Gem Version'
task :version_set do
  Oxidized.version_set
  Bundler::GemHelper.instance.gemspec.version = Oxidized::VERSION
end

desc 'Remove gems'
task :clean do
  FileUtils.rm_rf 'pkg'
end

desc 'Tag the release'
task :tag do
  system "git tag #{gemspec.version} -m 'Release #{gemspec.version}'"
end

desc 'Push to rubygems'
task push: :tag do
  system "gem push pkg/#{gemfile}"
end

desc 'Normalise file permissions'
task :chmod do
  xbit = %w[
    bin/oxidized
    bin/console
    extra/auto-reload-config.runit
    extra/nagios_check_failing_nodes.rb
    extra/oxidized-report-git-commits
    extra/oxidized.init
    extra/oxidized.init.d
    extra/oxidized.runit
    extra/syslog.rb
    extra/update-ca-certificates.runit
    extra/device2yaml.rb
  ]
  dirs = []
  %x(git ls-files -z).split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }.each do |file|
    dirs.push(File.dirname(file))
    xbit.include?(file) ? File.chmod(0o0755, file) : File.chmod(0o0644, file)
  end
  dirs.sort.uniq.each { |dir| File.chmod(0o0755, dir) }
end

# Build the container image with docker or podman
def command_available?(command)
  system("which #{command} > /dev/null 2>&1")
end

def docker_needs_root?
  !system('docker info > /dev/null 2>&1')
end

desc 'Build the container image with docker or podman'
task :build_container do
  branch_name = %x(git rev-parse --abbrev-ref HEAD).chop.gsub '/', '_'
  sha_hash = %x(git rev-parse --short HEAD).chop
  image_tag = "#{branch_name}-#{sha_hash}"

  # Prefer podman if available as it runs rootless
  if command_available?('podman')
    sh "podman build -t oxidized:#{image_tag} -t oxidized:latest ."
  elsif command_available?('docker')
    if docker_needs_root?
      puts 'docker needs root to build the image. Using sudo...'
      sh "sudo docker build -t oxidized:#{image_tag} -t oxidized:latest ."
    else
      sh "docker build -t oxidized:#{image_tag} -t oxidized:latest ."
    end
  else
    puts 'You need Podman or Docker to build the container image.'
    exit 1
  end
end

task default: %i[rubocop test]
