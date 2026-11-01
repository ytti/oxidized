require_relative '../spec_helper'
require 'oxidized/input/ssh'

describe Oxidized::SSH do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.config.timeout = 30
    Oxidized.config.input.ssh.secure = true
    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_input)
    Oxidized::Node.any_instance.stubs(:resolve_output)
    Resolv.any_instance.stubs(:getaddress).with('example.com').returns('192.0.2.2')
  end

  describe "#connect" do
    it "should use proxy command when proxy host given and connect by ip if resolve_dns is true" do
      Oxidized.config.resolve_dns = true
      @node = Oxidized::Node.new(name:     'example.com',
                                 input:    'ssh',
                                 output:   'git',
                                 model:    'junos',
                                 username: 'alma',
                                 password: 'armud',
                                 vars:     { "ssh_proxy" => 'test.com' })

      ssh = Oxidized::SSH.new

      model = mock
      model.expects(:cfg).returns('ssh' => [])
      @node.expects(:model).returns(model).at_least_once

      proxy = mock
      Net::SSH::Proxy::Command.expects(:new).with("ssh test.com -W [%h]:%p").returns(proxy)
      ssh_options = {
        port:                            22,
        verify_host_key:                 Oxidized.config.input.ssh.secure ? :always : :never,
        append_all_supported_algorithms: true,
        keepalive:                       true,
        forward_agent:                   false,
        password:                        'armud',
        timeout:                         Oxidized.config.timeout,
        number_of_password_prompts:      0,
        auth_methods:                    %w[none publickey password],
        proxy:                           proxy,
        logger:                          anything,
        max_win_size:                    2 * 1024 * 1024
      }
      Net::SSH.expects(:start).with('192.0.2.2', 'alma', ssh_options)

      ssh.instance_variable_set("@exec", true)
      ssh.connect(@node)
    end

    it "should use proxy command when proxy host given and connect by name if resolve_dns is false" do
      Oxidized.config.resolve_dns = false
      @node = Oxidized::Node.new(name:     'example.com',
                                 input:    'ssh',
                                 output:   'git',
                                 model:    'junos',
                                 username: 'alma',
                                 password: 'armud',
                                 vars:     { "ssh_proxy" => 'test.com' })

      ssh = Oxidized::SSH.new

      model = mock
      model.expects(:cfg).returns('ssh' => [])
      @node.expects(:model).returns(model).at_least_once

      proxy = mock
      Net::SSH::Proxy::Command.expects(:new).with("ssh test.com -W [%h]:%p").returns(proxy)
      ssh_options = {
        port:                            22,
        verify_host_key:                 Oxidized.config.input.ssh.secure ? :always : :never,
        append_all_supported_algorithms: true,
        keepalive:                       true,
        forward_agent:                   false,
        password:                        'armud',
        timeout:                         Oxidized.config.timeout,
        number_of_password_prompts:      0,
        auth_methods:                    %w[none publickey password],
        proxy:                           proxy,
        logger:                          anything,
        max_win_size:                    2 * 1024 * 1024
      }
      Net::SSH.expects(:start).with('example.com', 'alma', ssh_options)

      ssh.instance_variable_set("@exec", true)
      ssh.connect(@node)
    end
  end

  describe "#make_ssh_proxy_command" do
    it "keeps user@host and the port unchanged" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).with("ssh -p 2222 user@test.com -W [%h]:%p")
      ssh.make_ssh_proxy_command('user@test.com', 2222, true)
    end

    it "accepts the proxy port as a string" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).with("ssh -p 2222 test.com -W [%h]:%p")
      ssh.make_ssh_proxy_command('test.com', '2222', true)
    end

    it "accepts IPv4 and IPv6 addresses as proxy host" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).with("ssh user@192.0.2.1 -W [%h]:%p")
      Net::SSH::Proxy::Command.expects(:new).with("ssh 2001:db8::1 -W [%h]:%p")
      ssh.make_ssh_proxy_command('user@192.0.2.1', nil, true)
      ssh.make_ssh_proxy_command('2001:db8::1', nil, true)
    end

    it "escapes % in an IPv6 zone ID for net-ssh" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).with("ssh fe80::1%%eth0 -W [%h]:%p")
      ssh.make_ssh_proxy_command('fe80::1%eth0', nil, true)
    end

    it "rejects a proxy host that is not [user@]hostname or IP address" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).never
      ['test.com$(id)', 'test.com;id', 'test.com id', 'u$(id)@test.com', '@test.com',
       'a@b@test.com', '-test.com', 'test-.com', 'test..com', "test.com\nid"].each do |host|
        _ { ssh.make_ssh_proxy_command(host, nil, true) }.must_raise ArgumentError
      end
    end

    it "rejects a proxy port that is not an integer" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).never
      _ { ssh.make_ssh_proxy_command('test.com', '22;id', true) }.must_raise ArgumentError
    end

    it "rejects a proxy host starting with '-'" do
      ssh = Oxidized::SSH.new
      Net::SSH::Proxy::Command.expects(:new).never
      _ { ssh.make_ssh_proxy_command('-oProxyCommand=id', nil, true) }.must_raise ArgumentError
    end
  end

  describe ".rescue_fail" do
    it "returns RESCUE_FAIL from Oxidized::Input" do
      result = Oxidized::SSH.rescue_fail

      _(result[Errno::ECONNREFUSED]).must_equal :debug
      _(result[IOError]).must_equal :warn
      _(result[Timeout::Error]).must_equal :warn
      _(result[Errno::ECONNRESET]).must_equal :warn
    end
    it "returns its own RESCUE_FAIL" do
      result = Oxidized::SSH.rescue_fail

      # Check that SSH-specific exceptions are included
      _(result[Net::SSH::Disconnect]).must_equal :debug
      _(result[RuntimeError]).must_equal :warn
      _(result[Net::SSH::AuthenticationFailed]).must_equal :warn
    end
  end
  describe '#config_name' do
    it "returns the configuration name" do
      ssh = Oxidized::SSH.new
      _(ssh.config_name).must_equal 'ssh'
    end
  end

  describe '#cmd' do
    before(:each) do
      @ssh = Oxidized::SSH.new
      @node = Oxidized::Node.new(name:     'test.example.com',
                                 input:    'ssh',
                                 output:   'git',
                                 model:    'junos',
                                 username: 'admin',
                                 password: 'password')
      @ssh.instance_variable_set("@node", @node)
    end

    it "accepts a String command" do
      @ssh.instance_variable_set("@exec", true)
      mock_ssh = mock('Net::SSH')
      @ssh.instance_variable_set("@ssh", mock_ssh)

      mock_ssh.expects(:exec!).with("show version").returns("version output")

      result = @ssh.cmd("show version")
      _(result).must_equal "version output"
    end

    it "logs an error and raises ArgumentError when cmd is not a String" do
      @ssh.logger.expects(:error).with(
        'cmd must be a String (NilClass): nil @ test.example.com'
      )
      _(proc { @ssh.cmd(nil) }).must_raise ArgumentError
      @ssh.logger.expects(:error).with(
        'cmd must be a String (Integer): 123 @ test.example.com'
      )
      _(proc { @ssh.cmd(123) }).must_raise ArgumentError
    end
  end

  describe '#login' do
    before(:each) do
      @ssh = Oxidized::SSH.new
      @prompt = /^switch\#$/
      @password_prompt = /^Password:/
      @ssh.instance_variable_set(:@password, @password_prompt)
    end

    it "sends a configured credential" do
      node = mock("Oxidized::Node")
      node.stubs(name: 'switch.example.com', prompt: @prompt, auth: { password: 'secret' })
      @ssh.instance_variable_set(:@node, node)
      @ssh.expects(:expect).with([@prompt, @password_prompt]).returns(@password_prompt)
      @ssh.expects(:cmd).with('secret', nil)
      @ssh.expects(:expect).with([@prompt]).returns(@prompt)

      @ssh.login
    end

    it "logs an error and raises ArgumentError when a credential is missing" do
      node = mock("Oxidized::Node")
      node.stubs(name: 'switch.example.com', prompt: @prompt, auth: { password: nil })
      @ssh.instance_variable_set(:@node, node)
      @ssh.expects(:expect).with([@prompt, @password_prompt]).returns(@password_prompt)
      @ssh.logger.expects(:error).with('Missing password for CLI login at switch.example.com')
      @ssh.expects(:cmd).never

      error = _(proc { @ssh.login }).must_raise ArgumentError
      _(error.message).must_equal 'missing password for CLI login'
    end
  end
end
