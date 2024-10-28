require_relative 'model_helper'

describe 'model/ASA' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'asa')
  end

  it 'matches different prompts' do
    _("\rLAB-ASA12-Oxidized-IPv6> ").must_match Oxidized::Models::ASA.prompt
    _("\rLAB-ASA12-Oxidized-IPv6# ").must_match Oxidized::Models::ASA.prompt
  end

  it 'runs on 5515 with version 9.12(4)67' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/asa_5512_9.12-4-67_single-context.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
