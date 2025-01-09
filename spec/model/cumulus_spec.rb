require_relative 'model_helper'

describe 'model/Cumulus' do
  before(:each) do
    init_model_helper

    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'cumulus')
  end

  it 'runs on MSN2010 with Cumulus Linux 5.9.2 (nvue mode)' do
    skip 'TODO: needs to be adapted to ATOMS'
    # Reload node with vars cumulus_use_nvue set
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'cumulus',
                               vars:  { cumulus_use_nvue: true })

    mockmodel = MockSsh.new('data/cumulus:MSN2010_5.9.2_nvue:simulation.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'runs on VX with Cumulus Linux 5.4.0 (frr mode)' do
    skip 'TODO: needs to be adapted to ATOMS'
    # Reload node with vars cumulus_use_nvue set
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ssh',
                               model:    'cumulus',
                               username: 'alma',
                               password: 'armud',
                               vars:     { cumulus_routing_daemon: 'frr',
                                           enable:                 true })

    mockmodel = MockSsh.new('data/cumulus:VX_5.4.0_frr:simulation.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
