require_relative '../spec_helper'

describe 'Model apc_aos' do
  before(:each) do
    Oxidized.asetus = Asetus.new

    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)
  end

  it "fetches the configuration with ftp" do
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ftp',
                               output:   'file',
                               model:    'apc_aos',
                               username: 'alma',
                               password: 'armud',
                               prompt:   'test_prompt')
    Oxidized::FTP.any_instance.stubs(:connect).returns(true)
    Oxidized::FTP.any_instance.stubs(:node).returns(@node)
    Oxidized::FTP.any_instance.stubs(:connect_cli).returns(true)
    Oxidized::FTP.any_instance.stubs(:disconnect).returns(true)
    Oxidized::FTP.any_instance.stubs(:disconnect_cli).returns(true)
    # Make sure we only run "config.ini" an no other command
    Oxidized::FTP.any_instance.expects(:cmd).never
    Oxidized::FTP.any_instance.expects(:cmd).with("config.ini").returns(CONFIGURATION_FILE)

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal EXPECTED_RESULT
  end

  it "fetches the configuration with scp" do
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'scp',
                               output:   'file',
                               model:    'apc_aos',
                               username: 'alma',
                               password: 'armud',
                               prompt:   'test_prompt')
    Oxidized::SCP.any_instance.stubs(:connect).returns(true)
    Oxidized::SCP.any_instance.stubs(:node).returns(@node)
    Oxidized::SCP.any_instance.stubs(:connect_cli).returns(true)
    Oxidized::SCP.any_instance.stubs(:disconnect).returns(true)
    Oxidized::SCP.any_instance.stubs(:disconnect_cli).returns(true)
    # Make sure we only run "config.ini" an no other command
    Oxidized::SCP.any_instance.expects(:cmd).never
    Oxidized::SCP.any_instance.expects(:cmd).with("config.ini").returns(CONFIGURATION_FILE)

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal EXPECTED_RESULT
  end

  it "does not fetch the configiguration with ssh" do
    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ssh',
                               output:   'file',
                               model:    'apc_aos',
                               username: 'alma',
                               password: 'armud',
                               prompt:   'test_prompt')
    Oxidized::Node.logger.expects(:error)
                  .with("No suitable input found for example.com")

    status, = @node.run

    _(status).must_equal :fail
  end
end

# Not taking the whole configuration.
# For now, the model does only mask the generation date
# In the future, it may hide passwords, so I included a line with snmp community strings
CONFIGURATION_FILE = <<~HEREDOC.freeze
  ; Schneider Electric
  ; Network Management Card AOS v2.5.0.8
  ; Smart-UPS APP v2.5.0.6
  ; (c) 2023 Schneider Electric. All rights reserved.
  ; Configuration file, generated on 02/20/2024 at 09:27:23 by Administrator apc

  [NetworkTCP/IP]
  SystemIP=0.0.0.0
  SubnetMask=0.0.0.0
  DefaultGateway=0.0.0.0
  IPv4=enabled
  BootMode=DHCP Only
  HostName=myhostname
  DomainName=mydomain.local
  ; (...)

  [NetworkSNMP]
  ;    To change the User Profile Auth Phrase, or the
  ;    User Profile Encrypt Phrase, use the UserProfile#AuthPhrase, or
  ;    UserProfile#EncryptPhrase keywords respectively where # is
  ;    the number of the profile. i.e., UserProfile1EncryptPhrase=apc crypt passphrase
  Access=enabled
  AccessControl1Community=public
  AccessControl2Community=public
  ; (...)
HEREDOC

EXPECTED_RESULT = <<~HEREDOC.freeze
  ; Schneider Electric
  ; Network Management Card AOS v2.5.0.8
  ; Smart-UPS APP v2.5.0.6
  ; (c) 2023 Schneider Electric. All rights reserved.

  [NetworkTCP/IP]
  SystemIP=0.0.0.0
  SubnetMask=0.0.0.0
  DefaultGateway=0.0.0.0
  IPv4=enabled
  BootMode=DHCP Only
  HostName=myhostname
  DomainName=mydomain.local
  ; (...)

  [NetworkSNMP]
  ;    To change the User Profile Auth Phrase, or the
  ;    User Profile Encrypt Phrase, use the UserProfile#AuthPhrase, or
  ;    UserProfile#EncryptPhrase keywords respectively where # is
  ;    the number of the profile. i.e., UserProfile1EncryptPhrase=apc crypt passphrase
  Access=enabled
  AccessControl1Community=public
  AccessControl2Community=public
  ; (...)
HEREDOC
