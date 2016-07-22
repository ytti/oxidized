require 'spec_helper'
require 'oxidized/input/ssh'

describe Oxidized::SSH do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger
    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_input)
    Oxidized::Node.any_instance.stubs(:resolve_output)
    @node = Oxidized::Node.new(name: 'example.com',
                               input: 'ssh',
                               output: 'git',
                               model: 'junos',
                               username: 'alma',
                               password: 'armud',
                               vars: {ssh_proxy: 'test.com'})

  end

  describe "#connect" do
    it "should use proxy command when proxy host given" do
      ssh = Oxidized::SSH.new

      model = mock()
      model.expects(:cfg).returns({'ssh' => []})
      @node.expects(:model).returns(model)

      proxy = mock()
      Net::SSH::Proxy::Command.expects(:new).with("ssh test.com -W %h:%p").returns(proxy)
      Net::SSH.expects(:start).with('93.184.216.34', 'alma', {:port => 22, :password => 'armud', :timeout => Oxidized.config.timeout,
                                    :paranoid => Oxidized.config.input.ssh.secure, :auth_methods => ['none', 'publickey', 'password', 'keyboard-interactive'],
                                    :number_of_password_prompts => 0, :proxy => proxy})

      ssh.instance_variable_set("@exec", true)
      ssh.connect(@node)
    end
  end
end
