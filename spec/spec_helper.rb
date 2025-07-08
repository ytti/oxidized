require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'mocha/minitest'
require 'oxidized'

Oxidized.mgr = Oxidized::Manager.new
# The default log level is :info; uncomment & adapt to set another log level in the tests
# SemanticLogger.default_level = :debug
SemanticLogger.add_appender(io: $stderr)

def stub_oxidized_ssh
  Oxidized::SSH.any_instance.stubs(:connect).returns(true)
  Oxidized::SSH.any_instance.stubs(:node).returns(@node)
  Oxidized::SSH.any_instance.expects(:cmd).at_least(1).returns("this is a command output\nModel: mx960")
  Oxidized::SSH.any_instance.stubs(:connect_cli).returns(true)
  Oxidized::SSH.any_instance.stubs(:disconnect).returns(true)
  Oxidized::SSH.any_instance.stubs(:disconnect_cli).returns(true)
end

def stub_oxidized_ssh_fail
  Oxidized::SSH.any_instance.stubs(:connect).returns(false)
  Oxidized::SSH.any_instance.stubs(:node).returns(@node)
  Oxidized::SSH.any_instance.expects(:cmd).never
  Oxidized::SSH.any_instance.stubs(:connect_cli).returns(false)
  Oxidized::SSH.any_instance.stubs(:disconnect).returns(false)
  Oxidized::SSH.any_instance.stubs(:disconnect_cli).returns(false)
end
