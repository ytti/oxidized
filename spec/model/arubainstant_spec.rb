require_relative 'model_helper'

describe 'model/ArubaInstant' do
  before { init_model_helper }

  it 'removes secrets' do
    Oxidized.config.vars.remove_secret = true
    cfg = MockSsh.get_result(self, 'IAP515_8.10.0.6_VWLC').to_cfg

    _(cfg).wont_match(/AAAAAAAAAABBBBBBBBBBCCCCCCCCCC/)
    _(cfg).must_match(/snmp-server host 10.10.42.12 version 2c <secret removed> inform/)
    _(cfg).must_match(/hash-mgmt-user oxidized password hash <secret removed>/)
    _(cfg).must_match(/hash-mgmt-user rocks password hash <secret removed> usertype read-only/)
  end
end
