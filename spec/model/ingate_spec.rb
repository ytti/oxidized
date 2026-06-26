# frozen_string_literal: true

require_relative 'model_helper'
require 'oxidized/model/ingate'

describe 'Model Ingate' do
  before(:each) do
    init_model_helper

    @mock_node = mock('Oxidized::Node')
    @mock_node.stubs(:name).returns('ingate-1')
    @mock_node.stubs(:ip).returns('192.0.2.10')
    @mock_node.stubs(:group).returns('default')

    @mock_input = mock('Oxidized::Input')
    @mock_input.stubs(:output).returns(nil)

    # The config is downloaded over HTTP (a "config to CLI file"). The values
    # below are fabricated; the format mirrors a real SIParator export. The
    # command is an anonymous lambda, so the stub matches any argument.
    @config = <<~CONFIG
      # Unitname: example-sbc
      # Product: Software SIParator/Firewall
      # Version: 6.4.4
      # Timestamp: 2024-01-01 00:00:00

      load-factory --all
      modify-row snmp.snmp 1 community=public snmppassword=SNMPPW
      modify-row misc.settings 1 passwordtimeout=300 enable_psk_rw=on
      add-row qturn.default_password {id 1} password=s3cr3tpw
      add-row sip.trunks {id 1} trunkuserpassword=TRUNKPW radiussecret=RADSEC
      add-row vpn.ipsec {id 1} xauth_psk=XAUTHPSK configencpassphrase=ENCPASS
      add-row cwmp.acs {id 1} api_token=APITOKEN123
      add-row cert.acme_accounts {id 1} eabhmackey=FAKEHMACKEY1234567890 key="-----BEGIN PRIVATE KEY-----
      FAKEACMEKEYLINE
      -----END PRIVATE KEY-----"
      add-row cert.cert {id 1} cert_key="-----BEGIN PRIVATE KEY-----
      FAKECERTKEYLINE
      -----END PRIVATE KEY-----"
    CONFIG
    @mock_input.stubs(:cmd).returns(@config)

    @model = Ingate.new
    @model.input = @mock_input
    @model.node  = @mock_node
  end

  it 'removes the volatile Timestamp line and keeps the configuration' do
    @model.stubs(:vars).returns(nil)

    result = @model.get.to_cfg

    _(result).wont_match(/^# Timestamp:/)
    _(result).must_match(/^load-factory --all$/)
    _(result).must_match(/^add-row qturn\.default_password /)
  end

  it 'redacts secrets when remove_secret is set' do
    @model.stubs(:vars).returns(nil)
    @model.stubs(:vars).with(:remove_secret).returns(true)

    result = @model.get.to_cfg

    # secret values are gone (across the various field families)
    %w[s3cr3tpw SNMPPW TRUNKPW RADSEC XAUTHPSK ENCPASS APITOKEN123
       FAKEHMACKEY1234567890 FAKEACMEKEYLINE FAKECERTKEYLINE].each do |secret|
      _(result).wont_include(secret)
    end
    _(result).wont_include('community=public')
    # replaced with placeholders, field name kept
    %w[password snmppassword trunkuserpassword radiussecret configencpassphrase
       xauth_psk api_token eabhmackey community].each do |field|
      _(result).must_match(/\b#{field}=<secret hidden>/)
    end
    _(result).must_match(/\bkey="<secret hidden>"/)
    _(result).must_match(/cert_key="<secret hidden>"/)
    # lookalikes are NOT redacted
    _(result).must_match(/passwordtimeout=300/)
    _(result).must_match(/enable_psk_rw=on/)
  end
end
