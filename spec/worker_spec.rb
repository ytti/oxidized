require_relative 'spec_helper'
require 'oxidized/worker'

describe Oxidized::Worker do
  describe '#significant_changes?' do
    before do
      @mock_job = mock('Oxidized::Job')
      @mock_node = mock('Oxidized::Node')
      @mock_output = mock('Oxidized output')
      @mock_model = mock('Oxidized model')

      @mock_job.stubs(:node).returns @mock_node
      @mock_node.stubs(:model).returns @mock_model
      @mock_node.stubs(:name).returns "SW1"
      @mock_node.stubs(:group).returns nil
      @mock_model.stubs(:vars).returns nil

      @old_config =
        "Last configuration change at 00001\n" \
        "NVRAM config last updated at 00001\n" \
        "Configuration Version 0000A\n"
      @mock_output.stubs(:fetch).returns @old_config
    end
    it 'returns true when output_store_mode is not specified' do
      config =
        "Last configuration change at 00002\n" \
        "NVRAM config last updated at 00002\n" \
        "Configuration Version 0000A\n"

      @mock_job.stubs(:config).returns config
      result = Oxidized::Worker.significant_changes?(@mock_job, @mock_output)
      _(result).must_equal true
    end

    it 'returns true even if config is unchanged when output_store_mode is not specified' do
      @mock_job.stubs(:config).returns @old_config
      result = Oxidized::Worker.significant_changes?(@mock_job, @mock_output)
      _(result).must_equal true
    end

    it 'returns true when output_store_mode=on_significant and significant changes exist' do
      @mock_model.stubs(:vars).with(:output_store_mode).returns 'on_significant'
      outputs = Oxidized::Model::Outputs.new
      outputs << "Last configuration change at 00002\n"
      outputs << "NVRAM config last updated at 00002\n"
      outputs << "Configuration Version 0000B\n"

      significant_config = "Configuration Version 0000B\n"
      @mock_model.expects(:significant_changes).with(outputs.to_cfg).returns significant_config
      @mock_model.expects(:significant_changes).with(@old_config).returns "Configuration Version 0000A\n"

      @mock_job.stubs(:config).returns outputs
      result = Oxidized::Worker.significant_changes?(@mock_job, @mock_output)
      _(result).must_equal true
    end

    it 'returns false when output_store_mode=on_significant and no significant change' do
      @mock_model.stubs(:vars).with(:output_store_mode).returns 'on_significant'
      outputs = Oxidized::Model::Outputs.new
      outputs << "Last configuration change at 00002\n"
      outputs << "NVRAM config last updated at 00002\n"
      outputs << "Configuration Version 0000A\n"
      @mock_job.stubs(:config).returns outputs

      significant_config = "Configuration Version 0000A\n"
      @mock_model.expects(:significant_changes).with(outputs.to_cfg).returns significant_config
      @mock_model.expects(:significant_changes).with(@old_config).returns "Configuration Version 0000A\n"

      result = Oxidized::Worker.significant_changes?(@mock_job, @mock_output)
      _(result).must_equal false
    end
  end
end
