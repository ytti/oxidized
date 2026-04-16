require 'time'

module Oxidized
  class CLI
    module Support
      SENSITIVE_NAME_RE = /(password|passphrase|secret|token|
                            (private|api|access)_?key|
                            community|credential|auth
                          )/ix
      ROOT_GEMS = %w[oxidized oxidized-web].freeze
      EXPLICIT_ENV_KEYS = %w[
        OXIDIZED_HOME
        OXIDIZED_LOGS
        CONFIG_RELOAD_INTERVAL
        UPDATE_CA_CERTIFICATES
      ].freeze

      private

      def show_support_details
        print_intro
        print_environment
        print_config_files
        print_rugged_support
        print_installed_gems
      end

      def print_intro
        os_release = read_os_release
        runit_path = '/etc/service/oxidized/run'

        puts '> :warning:'
        puts '> The --support option is intended for diagnostic purposes and may include sensitive information.'
        puts '> Remove any sensitive data before sharing this output.'
        puts
        puts '## Oxidized Support Data'
        puts "- Timestamp: #{Time.now.utc.iso8601}"
        puts "- Oxidized version: #{Oxidized::VERSION_FULL}"
        puts "- OS release: #{os_release}" if os_release
        puts "- Container hint (#{runit_path} exists): #{File.exist?(runit_path)}"
        puts "- Ruby engine: #{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'}"
        puts "- Ruby version: #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
        puts "- Working directory: #{Dir.pwd}"
        puts "- Gem paths: #{Gem.path.join(', ')}"
        puts
      end

      def print_environment
        puts '### Environment Variables'
        keys = (ENV.keys.grep(/^OXIDIZED_/) + EXPLICIT_ENV_KEYS).uniq.sort

        keys.each do |key|
          next unless ENV.key?(key)

          value = ENV.fetch(key)
          puts key.match?(SENSITIVE_NAME_RE) ? "#{key}=[REDACTED]" : "#{key}=#{value}"
        end

        puts
      end

      def print_config_files
        puts '### Configuration Files'
        config_paths.each do |path|
          config_path = File.expand_path(path)
          exists = File.exist?(config_path)
          puts "- #{config_path} exists: #{exists ? 'yes' : 'no'}"
          next unless exists

          print_sanitized_config(config_path)
        end
        puts
      end

      def print_rugged_support
        puts '### Rugged'
        begin
          require 'rugged'
          puts "- Rugged version: #{Rugged::VERSION}"

          ssh_supported = Rugged.respond_to?(:features) && Rugged.features.include?(:ssh)
          puts "- Rugged SSH support: #{ssh_supported}"
        rescue LoadError
          puts '- Rugged: not available'
          puts '- Rugged SSH support: false'
        end
        puts
      end

      def print_installed_gems
        puts '### Relevant Installed Gems'
        relevant_gem_names.each do |name|
          versions = Gem::Specification.find_all_by_name(name).sort_by(&:version).map { |s| s.version.to_s }
          puts "- #{name} (#{versions.join(', ')})" unless versions.empty?
        end
      end

      def relevant_gem_names
        names = ROOT_GEMS.select { |name| Gem::Specification.any? { |s| s.name == name } }

        root_specs = names.flat_map { |name| Gem::Specification.find_all_by_name(name) }
        runtime_deps = root_specs.flat_map { |spec| spec.dependencies }
        names.concat(runtime_deps.map(&:name))
        names.sort.uniq
      end

      def config_paths
        user_default = File.join(Dir.home, '.config', 'oxidized', 'config')
        home_from_env = File.join(File.expand_path(Oxidized::Config::ROOT), 'config')

        [
          '/etc/oxidized/config',
          user_default,
          home_from_env
        ].uniq
      end

      def print_sanitized_config(path)
        content = File.read(path)
        puts '```yaml'
        content.each_line(chomp: true) do |line|
          key, separator, = line.partition(':')

          if separator.empty? || key.empty?
            puts line
            next
          end

          if key.match?(SENSITIVE_NAME_RE)
            puts "#{key}: [REDACTED]"
          else
            puts line
          end
        end
        puts '```'
      rescue StandardError => e
        puts "    <failed to read: #{e.class}: #{e.message}>"
      end

      def read_os_release
        return nil unless File.exist?('/etc/os-release')

        line = File.foreach('/etc/os-release').find { |entry| entry.start_with?('PRETTY_NAME=') }
        return nil unless line

        line.split('=', 2).last.to_s.strip.gsub(/^"|"$/, '')
      rescue StandardError
        nil
      end
    end
  end
end
