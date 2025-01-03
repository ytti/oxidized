require_relative 'model_helper'

describe 'model/XOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'xos')
  end

  it 'runs on X460-48T with XOS 16.2.5.4' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/xos_X460-48t_16.2.5.4.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'removes secrets from X460-48T 16.2.5.4' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new('examples/device-simulation/yaml/xos_X460-48t_16.2.5.4.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_match(/<secret hidden>/)
    _(result.to_cfg).wont_match(/lskdjf9098234NDFSKJDHF23420398NDJK9834534gkjjdhfMn3=/)
    _(result.to_cfg).wont_match(/lkdjfLDKFJS09fsdlfksd09s8flkds==/)
    _(result.to_cfg).wont_match(/$5$7LKDJSF8973lkjDSlJgLKJgslkjgLKjgldksjgS879SDlkgkld/)
    _(result.to_cfg).wont_match(/$5$dlkdfj$.09234lkdfjgLKDJ08952GKLJlsdgjkkjlhH2335234/)
  end
end
