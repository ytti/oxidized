require_relative '../spec_helper'
require 'oxidized/cli/support'

# Helper class that mixes in the Support module so private methods
# can be tested in isolation via #send.
class SupportTestHelper
  include Oxidized::CLI::Support
end

describe Oxidized::CLI::Support do
  before do
    @helper = SupportTestHelper.new
  end

  let(:exhaustive_config) { File.join(__dir__, 'data', 'exhaustive_config.yaml') }

  describe 'SENSITIVE_NAME_RE' do
    %w[password passphrase secret token community credential
       private_key api_key access_key enable].each do |word|
      it "matches #{word}" do
        _(word).must_match Oxidized::CLI::Support::SENSITIVE_NAME_RE
      end
    end

    %w[hostname interval output model].each do |word|
      it "does not match #{word}" do
        _(word).wont_match Oxidized::CLI::Support::SENSITIVE_NAME_RE
      end
    end
  end

  describe '#print_sanitized_config' do
    it 'produces the expected sanitized output' do
      expected = File.read(File.join(__dir__, 'data', 'exhaustive_config#output.txt'))
      out, _err = capture_io { @helper.send(:print_sanitized_config, exhaustive_config) }
      _(out).must_equal expected
    end

    it 'handles nonexistent files gracefully' do
      out, _err = capture_io { @helper.send(:print_sanitized_config, '/nonexistent/path/config') }

      _(out).must_include '<failed to read:'
    end
  end

  describe '#read_os_release' do
    data_dir = File.join(__dir__, 'data')
    Dir.glob(File.join(data_dir, 'os-release#*')).each do |fixture|
      expected = File.basename(fixture).split('#', 2).last.gsub('_', '/')
      it "returns '#{expected}'" do
        File.stubs(:exist?).with('/etc/os-release').returns(true)
        File.stubs(:foreach).with('/etc/os-release').returns(File.readlines(fixture))

        _(@helper.send(:read_os_release)).must_equal expected
      end
    end

    it 'returns nil when /etc/os-release does not exist' do
      File.stubs(:exist?).with('/etc/os-release').returns(false)

      _(@helper.send(:read_os_release)).must_be_nil
    end

    it 'returns nil when PRETTY_NAME is absent' do
      File.stubs(:exist?).with('/etc/os-release').returns(true)
      File.stubs(:foreach).with('/etc/os-release').returns(["ID=alpine\n", "VERSION_ID=3.19\n"])

      _(@helper.send(:read_os_release)).must_be_nil
    end
  end

  describe '#print_environment' do
    it 'redacts sensitive OXIDIZED_ env variables' do
      fake_env = {
        'OXIDIZED_PASSWORD'       => 'topsecret',
        'OXIDIZED_SSH_PASSPHRASE' => 'topsecret',
        'OXIDIZED_HOME'           => '/srv/oxidized'
      }
      ENV.stubs(:keys).returns(fake_env.keys)
      ENV.stubs(:has_key?).returns(false)
      fake_env.each_key { |k| ENV.stubs(:has_key?).with(k).returns(true) }
      fake_env.each { |k, v| ENV.stubs(:fetch).with(k).returns(v) }

      out, _err = capture_io { @helper.send(:print_environment) }

      _(out).must_include 'OXIDIZED_HOME=/srv/oxidized'
      _(out).must_include 'OXIDIZED_PASSWORD=[REDACTED]'
      _(out).must_include 'OXIDIZED_SSH_PASSPHRASE=[REDACTED]'
      _(out).wont_include 'topsecret'
    end
  end
end
