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

    describe 'oxidized-web version check' do
      before do
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
      end

      it 'warns when oxidized-web is older than the minimum version' do
        Oxidized::Core.any_instance.stubs(:web_version).returns('0.16.0')
        Oxidized::Core.logger.expects(:warn).with(regexp_matches(/oxidized-web 0\.16\.0 is older than 0\.17\.0/))

        Oxidized::Core.new(nil)
      end

      it 'does not warn when oxidized-web is recent enough' do
        Oxidized::Core.any_instance.stubs(:web_version).returns('0.17.0')
        Oxidized::Core.logger.expects(:warn).never

        Oxidized::Core.new(nil)
      end

      it 'does not warn when the oxidized-web version is unknown' do
        Oxidized::Core.any_instance.stubs(:web_version).returns(nil)
        Oxidized::Core.logger.expects(:warn).never

        Oxidized::Core.new(nil)
      end
    end
  end
end
