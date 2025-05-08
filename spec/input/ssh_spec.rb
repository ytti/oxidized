require_relative '../spec_helper'
require 'oxidized/input/ssh'

describe Oxidized::SSH do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.asetus.cfg.debug = false
    Oxidized.setup_logger
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
                                 vars:     { ssh_proxy: 'test.com' })

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
        proxy:                           proxy
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
                                 vars:     { ssh_proxy: 'test.com' })

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
        proxy:                           proxy
      }
      Net::SSH.expects(:start).with('example.com', 'alma', ssh_options)

      ssh.instance_variable_set("@exec", true)
      ssh.connect(@node)
    end
  end
end
