require_relative 'model_helper'

describe 'model/IOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'ios')
  end

  it 'matches different prompts' do
    _('LAB-SW123_9200L#').must_match IOS.prompt
    _('OXIDIZED-WLC1#').must_match IOS.prompt
  end

  it 'runs on C9200L-24P-4G with IOS-XE 17.09.04a' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/iosxe_C9200L-24P-4G_17.09.04a.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'runs on C9800-L-F-K9 with IOS-XE 17.06.05' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/iosxe_C9800-L-F-K9_17.06.05.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'runs on ASR920 with IOS 16.8.1b' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/asr920_16.8.1b.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'removes secrets' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new('examples/device-simulation/yaml/iosxe_C9200L-24P-4G_17.09.04a.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).wont_match(/SECRET/)
    _(result.to_cfg).wont_match(/public/)
    _(result.to_cfg).wont_match(/AAAAAAAAAABBBBBBBBBB/)
  end

  it 'removes secrets from IOS-XE WLCs' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new('examples/device-simulation/yaml/iosxe_C9800-L-F-K9_17.06.05.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).wont_match(/SECRET_REMOVED/)
    _(result.to_cfg).wont_match(/REMOVED_SECRET/)
    _(result.to_cfg).wont_match(/WLANSECR3T/)
    _(result.to_cfg).wont_match(/WLAN SECR3T/)
    _(result.to_cfg).wont_match(/7df35f90c92ecff2a803e79577b85e978edc0a76404f6cfb534df8d9f9f67beb/)
    _(result.to_cfg).wont_match(/DOT1XPASSW0RD/)
    _(result.to_cfg).wont_match(/MGMTPASSW0RD/)
    _(result.to_cfg).wont_match(/MGMTSECR3T/)
    _(result.to_cfg).wont_match(/DOT1X PASSW0RD/)
    _(result.to_cfg).wont_match(/MGMT PASSW0RD/)
    _(result.to_cfg).wont_match(/MGMT SECR3T/)
  end
end
