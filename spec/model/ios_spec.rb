require_relative 'model_helper'

describe 'model/IOS' do
  before { init_model_helper }

  it 'removes secrets' do
    Oxidized.config.vars.remove_secret = true
    test = ATOMS::TestOutput.new('ios', 'C9200L-24P-4G_17.09.04a')
    cfg = MockSsh.get_result(self, test).to_cfg

    _(cfg).wont_match(/SECRET/)
    _(cfg).wont_match(/public/)
    _(cfg).wont_match(/AAAAAAAAAABBBBBBBBBB/)
  end

  it 'removes secrets from IOS-XE WLCs' do
    Oxidized.config.vars.remove_secret = true
    test = ATOMS::TestOutput.new('ios', 'C9800-L-F-K9_17.06.05')
    cfg = MockSsh.get_result(self, test).to_cfg

    _(cfg).wont_match(/SECRET_REMOVED/)
    _(cfg).wont_match(/REMOVED_SECRET/)
    _(cfg).wont_match(/WLANSECR3T/)
    _(cfg).wont_match(/WLAN SECR3T/)
    _(cfg).wont_match(/7df35f90c92ecff2a803e79577b85e978edc0a76404f6cfb534df8d9f9f67beb/)
    _(cfg).wont_match(/DOT1XPASSW0RD/)
    _(cfg).wont_match(/MGMTPASSW0RD/)
    _(cfg).wont_match(/MGMTSECR3T/)
    _(cfg).wont_match(/DOT1X PASSW0RD/)
    _(cfg).wont_match(/MGMT PASSW0RD/)
    _(cfg).wont_match(/MGMT SECR3T/)
  end
end
