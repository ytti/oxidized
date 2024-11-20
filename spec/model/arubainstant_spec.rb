require_relative 'model_helper'

describe 'model/IOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'arubainstant')
  end

  it "matches different prompts" do
    # Virtual controller - ArubaOS (MODEL: 515), Version 8.10.0.7 LSR
    _('AAAA-AP123456# ').must_match ArubaInstant.prompt
  end

  it 'runs on IAP516 with 8.10.0.6' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/arubainstant_IAP515_8.10.0.6_VWLC.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'removes secrets' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new('examples/device-simulation/yaml/arubainstant_IAP515_8.10.0.6_VWLC.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).wont_match(/AAAAAAAAAABBBBBBBBBBCCCCCCCCCC/)
    _(result.to_cfg).must_match(/snmp-server host 10.10.42.12 version 2c <secret removed> inform/)
    _(result.to_cfg).must_match(/hash-mgmt-user oxidized password hash <secret removed>/)
    _(result.to_cfg).must_match(/hash-mgmt-user rocks password hash <secret removed> usertype read-only/)
  end
end
