require_relative 'model_helper'

describe 'model/Aoscx' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'aoscx')
  end

  it 'matches different prompts' do
    _('LAB-SW1234# ').must_match Aoscx.prompt
  end

  it 'runs on R8N85A (C6000-48G-CL4) with PL.10.08.1010' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/aoscx_R8N85A-C6000-48G-CL4_PL.10.08.1010.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'runs on R8N85A (C6000-48G-CL4) with PL.10.08.1010' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/aoscx_R0X25A-6410_FL.10.10.1100.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
