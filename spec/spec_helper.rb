require 'minitest/autorun'
require 'mocha/mini_test'
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
