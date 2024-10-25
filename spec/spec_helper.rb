require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  if ENV['CI']
    formatter SimpleCov::Formatter::CoberturaFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::CoberturaFormatter,
        SimpleCov::Formatter::HTMLFormatter
      ]
    )
  end
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'oxidized'

Oxidized.mgr = Oxidized::Manager.new

def stub_oxidized_ssh
  Oxidized::Input::SSH.any_instance.stubs(:connect).returns(true)
  Oxidized::Input::SSH.any_instance.stubs(:node).returns(@node)
  Oxidized::Input::SSH.any_instance.expects(:cmd).at_least(1).returns("this is a command output\nModel: mx960")
  Oxidized::Input::SSH.any_instance.stubs(:connect_cli).returns(true)
  Oxidized::Input::SSH.any_instance.stubs(:disconnect).returns(true)
  Oxidized::Input::SSH.any_instance.stubs(:disconnect_cli).returns(true)
end

def stub_oxidized_ssh_fail
  Oxidized::Input::SSH.any_instance.stubs(:connect).returns(false)
  Oxidized::Input::SSH.any_instance.stubs(:node).returns(@node)
  Oxidized::Input::SSH.any_instance.expects(:cmd).never
  Oxidized::Input::SSH.any_instance.stubs(:connect_cli).returns(false)
  Oxidized::Input::SSH.any_instance.stubs(:disconnect).returns(false)
  Oxidized::Input::SSH.any_instance.stubs(:disconnect_cli).returns(false)
end
