require_relative 'model_helper'

describe 'model/Cumulus' do
  before(:each) do
    init_model_helper

    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'cumulus')
  end

  it 'matches different prompts' do
    _('root@spine1-nyc2:~# ').must_match Cumulus.prompt
    # Prompts within mgmt vrf
    _('cumulus@cumulus:mgmt:~$ ').must_match Cumulus.prompt
    _('root@cumulus:mgmt:~# ').must_match Cumulus.prompt

    # Prompt polluted by a previous command not ending with \n
    _('#root@cumulus:mgmt:~# ').must_match Cumulus.prompt

    # Prompt with ESC Codes
    prompt = "\e[?2004hroot@spine1-nyc2:~# "
    # Remove the ESC Codes
    prompt = @node.model.expects prompt
    _(prompt).must_match Cumulus.prompt
  end

  it 'runs on MSN2010 with Cumulus Linux 5.9.2 (nvue mode)' do
    # Reload node with vars cumulus_use_nvue set
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'cumulus',
                               vars:  { cumulus_use_nvue: true })

    mockmodel = MockSsh.new('examples/device-simulation/yaml/cumulus_MSN2010_5.9.2_nvue.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'runs on VX with Cumulus Linux 5.4.0 (frr mode)' do
    # Reload node with vars cumulus_use_nvue set
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ssh',
                               model:    'cumulus',
                               username: 'alma',
                               password: 'armud',
                               vars:     { cumulus_routing_daemon: 'frr',
                                           enable:                 true })

    mockmodel = MockSsh.new('examples/device-simulation/yaml/cumulus_VX_5.4.0_frr.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
