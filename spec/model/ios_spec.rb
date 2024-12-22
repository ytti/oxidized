require_relative 'model_helper'
require_relative 'atoms'

describe 'model/IOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'ios')
  end

  it 'removes secrets' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new(ATOMS::TestOutput.new('ios', 'C9200L-24P-4G_17.09.04a'))
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).wont_match(/SECRET/)
    _(result.to_cfg).wont_match(/public/)
    _(result.to_cfg).wont_match(/AAAAAAAAAABBBBBBBBBB/)
  end

  it 'removes secrets from IOS-XE WLCs' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new(ATOMS::TestOutput.new('ios', 'C9800-L-F-K9_17.06.05'))
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
