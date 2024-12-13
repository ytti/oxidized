require_relative 'model_helper'

describe 'model/OpnSense' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'opnsense')
  end

  # We do not need to match prompts as the model works in exec mode

  it 'runs on nano 23.7' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/opnsense_nano_23.7.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
