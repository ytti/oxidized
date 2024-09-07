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
end
