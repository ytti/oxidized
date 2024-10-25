require_relative 'model_helper'

describe 'model/RouterOS' do
  before(:each) do
    init_model_helper
    # Oxidized.asetus.cfg.debug = true
    # Oxidized.setup_logger
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'routeros')
  end

  # We do not need to check prompts as RouterOS runs in exec mode

  it 'runs on CHR with 7.10.1' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/routeros_CHR_7.10.1.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
