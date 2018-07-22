require 'simplecov'
SimpleCov.start

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'oxidized'

Oxidized.mgr = Oxidized::Manager.new

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
