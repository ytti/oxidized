require_relative 'model_helper'

describe 'Model Cumulus' do
  before(:each) do
    init_model_helper
  end

  it 'runs on MSN2010 with Cumulus Linux 5.9.2 (nvue mode)' do
    # Reload node with vars cumulus_use_nvue set
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'cumulus',
                               vars:  { "cumulus_use_nvue" => true })

    model = YAML.load_file('spec/model/data/cumulus#MSN2010_5.9.2_nvue#custom_simulation.yaml')
    mockmodel = MockSsh.new(model)
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.interpolate_yaml(model['oxidized_output'])
  end

  it 'runs on VX with Cumulus Linux 5.4.0 (frr mode)' do
    # Reload node with vars cumulus_use_nvue set
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ssh',
                               model:    'cumulus',
                               username: 'alma',
                               password: 'armud',
                               vars:     { "cumulus_routing_daemon" => 'frr',
                                           "enable"                 => true })

    model = YAML.load_file('spec/model/data/cumulus#VX_5.4.0_frr#custom_simulation.yaml')
    mockmodel = MockSsh.new(model)
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.interpolate_yaml(model['oxidized_output'])
  end
end
