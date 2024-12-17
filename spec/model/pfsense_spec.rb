require_relative 'model_helper'

describe 'model/pfense' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'pfsense')
  end

  # We do not need to match prompts as the model works in exec mode

  it 'runs on CE 2.7.2' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/pfSense_CE_2.7.2.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
