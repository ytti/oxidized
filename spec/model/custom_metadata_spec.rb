require_relative '../spec_helper'
require 'oxidized/model/opnsense'
require 'oxidized/model/pfsense'

# Testing models with custom metatada

describe 'custom metadata models' do
  before do
    Oxidized.asetus = Asetus.new

    @mock_node = mock('Oxidized::Node')
    @mock_node.stubs(:name).returns('router1')
    @mock_node.stubs(:ip).returns('192.168.1.1')
    @mock_node.stubs(:group).returns('gr1')

    @mock_input = mock('Oxidized::Input')
    @mock_input.stubs(:output).returns(nil)
    @mock_input.stubs(:cmd).returns("not implemented.\n")
  end
  describe 'OpnSense' do
    it 'adds an xmmlcomment for metadata' do
      model = OpnSense.new
      model.input = @mock_input
      model.node = @mock_node
      model.stubs(:vars).returns(nil)
      model.stubs(:vars).with('metadata').returns(true)

      result = model.get.to_cfg
      _(result).must_include '<!-- # Fetched by Oxidized with model OpnSense from host router1 [192.168.1.1] -->'
    end
  end

  describe 'PfSense' do
    it 'adds an xmmlcomment for metadata' do
      model = PfSense.new
      model.input = @mock_input
      @mock_input.stubs(:cmd).returns("<pfsense>command</pfsense>\n")

      model.node = @mock_node
      model.stubs(:vars).returns(nil)
      model.stubs(:vars).with('metadata').returns(true)

      result = model.get.to_cfg
      _(result).must_include '<!-- # Fetched by Oxidized with model PfSense from host router1 [192.168.1.1] -->'
    end
  end
end
