require_relative 'spec_helper'
require 'oxidized/core'
require 'oxidized/web'

describe Oxidized::Core do
  before do
    Oxidized.asetus = Asetus.new

    Oxidized::Manager.expects(:new)
    Oxidized.stubs(:mgr=)

    Oxidized::HookManager.expects(:from_config)
    Oxidized.stubs(:hooks=)

    @mock_nodes = mock('Oxidized::Nodes')
    @mock_nodes.expects(:empty?).returns(false)
    Oxidized::Nodes.expects(:new).returns(@mock_nodes)

    Oxidized::Worker.expects(:new)
    Oxidized::Signals.expects(:register_signal)
  end

  describe '#initialize' do
    it 'runs when extensions not configured' do
      Oxidized::Core.any_instance.expects(:run)

      Oxidized::Core.new(nil)
    end

    it 'runs when only extensions configured' do
      Oxidized.config.extensions = nil
      Oxidized::Core.any_instance.expects(:run)

      Oxidized::Core.new(nil)
    end
    it 'runs when only extensions.oxidized-web configured' do
      Oxidized.config.extensions = Asetus::ConfigStruct.new(
        {
          "oxidized-web" => nil
        }
      )
      Oxidized::Core.any_instance.expects(:run)
      Oxidized::Core.any_instance.expects(:require).with('oxidized/web').never

      Oxidized::Core.new(nil)
    end
    it 'wont run oxidized-web when load = false' do
      Oxidized.config.extensions = Asetus::ConfigStruct.new(
        {
          "oxidized-web" => { "load" => false }
        }
      )
      Oxidized::Core.any_instance.expects(:run)
      Oxidized::Core.any_instance.expects(:require).with('oxidized/web').never

      Oxidized::Core.new(nil)
    end
    it 'runs oxidized-web when load = true' do
      Oxidized.config.extensions = Asetus::ConfigStruct.new(
        {
          "oxidized-web" => { "load" => true }
        }
      )
      Oxidized::Core.any_instance.expects(:require).with('oxidized/web')
      mock_web = mock('Oxidized::API::Web')
      mock_web.expects(:run)
      Oxidized::API::Web.expects(:new).returns(mock_web)
      Oxidized::Core.any_instance.expects(:run)

      Oxidized::Core.new(nil)
    end
  end
end
