require_relative 'model_helper'
require 'json'

using Refinements

describe 'Model Enterprise SONiC' do
  before(:each) do
    init_model_helper
    @fixture = File.join(__dir__, 'data', 'enterprise_sonic#KVM_4.6.0_admin')
    simulation = YAML.load_file("#{@fixture}#custom_simulation.yaml")
    @simulation = simulation
    @node = Oxidized::Node.new(name: 'example.com', input: 'ssh', model: 'enterprise_sonic',
                               vars: { 'admin' => true })
    Net::SSH.stubs(:start).returns(MockSsh.new(simulation))
  end

  it 'collects CLI configuration and separate JSON from a Linux login' do
    @node.vars['config_db_backup'] = true
    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal File.read("#{@fixture}#custom_output.txt")
    _(result.types).must_equal ['json']
    _(result.type('json').size).must_equal 1
    json = result.type('json').first
    _(json.name).must_equal 'json'
    _(JSON.parse(json)).must_equal JSON.parse(File.read("#{@fixture}#output.json"))
  end

  it 'collects only CLI configuration by default and exits both shells' do
    @simulation['commands'].reject! { |command| command.has_key?("show runningconfiguration all\n") }
    Net::SSH.stubs(:start).returns(MockSsh.new(@simulation))

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal File.read("#{@fixture}#custom_output.txt")
    _(result.types).must_be_empty
  end
end
