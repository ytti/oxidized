# frozen_string_literal: true

require_relative 'model_helper'
require 'oxidized/model/ivanti'

describe 'Model Ivanti' do
  before(:each) do
    init_model_helper

    @mock_node = mock('Oxidized::Node')
    @mock_node.stubs(:name).returns('ivanti-1')
    @mock_node.stubs(:ip).returns('192.0.2.10')
    @mock_node.stubs(:group).returns('default')

    @mock_input = mock('Oxidized::Input')
    @mock_input.stubs(:output).returns(nil)

    @api_response = <<~BASE64
      AAAA
      BBBB
      CCCC
      1234
    BASE64

    @mock_input
      .stubs(:cmd)
      .with(Ivanti::BINARY_CONFIG_PATH)
      .returns(@api_response)

    @model = Ivanti.new
    @model.input = @mock_input
    @model.node  = @mock_node

    @model.stubs(:vars).returns(nil)
  end

  it 'joins multiline base64 body into a single line' do
    result = @model.get.to_cfg

    _(result).must_equal 'AAAABBBBCCCC1234'
  end
end
