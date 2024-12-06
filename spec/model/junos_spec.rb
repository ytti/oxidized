require_relative 'model_helper'

describe 'model/junos' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'junos')
  end

  it 'runs on SRX300 with 22.4' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/junos_srx300_22.4.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    #result2file(result, 'model-output.txt')
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
