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
    before do
      @model = OpnSense.new
      @model.input = @mock_input
      @model.node = @mock_node
      @model.stubs(:vars).returns(nil)
      @model.stubs(:vars).with('metadata').returns(true)
    end

    it 'adds an xmlcomment for metadata' do
      result = @model.get.to_cfg
      _(result).must_include '<!-- # Fetched by Oxidized with model OpnSense from host router1 [192.168.1.1] -->'
    end

    it 'uses vars("metadata_bottom") if present' do
      @model.stubs(:vars).with('metadata_bottom').returns("# bottom\n")
      @model.stubs(:vars).with('metadata_top').returns("# top\n")

      result = @model.get.to_cfg
      _(result).must_include '<!-- # bottom -->'
    end

    it 'uses vars("metadata_top") if present and vars("metadata_bottom is not defined")' do
      @model.stubs(:vars).with('metadata_top').returns("# top\n")

      result = @model.get.to_cfg
      _(result).must_include '<!-- # top -->'
    end
  end

  describe 'PfSense' do
    before do
      @model = PfSense.new
      @model.input = @mock_input
      @model.node = @mock_node
      @model.stubs(:vars).returns(nil)
      @model.stubs(:vars).with('metadata').returns(true)
      @mock_input.stubs(:cmd).returns("<pfsense>command</pfsense>\n")
    end

    it 'adds an xmmlcomment for metadata' do
      result = @model.get.to_cfg
      _(result).must_include '<!-- # Fetched by Oxidized with model PfSense from host router1 [192.168.1.1] -->'
    end

    it 'uses vars("metadata_bottom") if present' do
      @model.stubs(:vars).with('metadata_bottom').returns("# bottom\n")
      @model.stubs(:vars).with('metadata_top').returns("# top\n")

      result = @model.get.to_cfg
      _(result).must_include '<!-- # bottom -->'
    end

    it 'uses vars("metadata_top") if present and vars("metadata_bottom is not defined")' do
      @model.stubs(:vars).with('metadata_top').returns("# top\n")

      result = @model.get.to_cfg
      _(result).must_include '<!-- # top -->'
    end
  end
end
