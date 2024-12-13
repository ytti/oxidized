require_relative 'model_helper'

describe 'model/Garderos' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'garderos')
  end

  it 'matches different prompts' do
    # Prompt without ANSI ESC Codes
    _('LAB-R1234_Garderos# ').must_match Garderos.prompt

    # Same prompt with ANSI ESC Codes, cleaned by the model
    prompt = "\e[4m\rLAB-R1234_Garderos#\e[m "
    prompt = @node.model.expects prompt
    _(prompt).must_match Garderos.prompt
  end

  it 'runs on R7709 with OS 003_006_068' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/garderos_R7709_003_006_068.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end
end
