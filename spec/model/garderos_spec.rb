require_relative 'model_helper'

describe 'model/Garderos' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'garderos')
  end

  it 'matches different prompts' do
    # Same prompt with ANSI ESC Codes, cleaned by the model
    prompt = "\e[4m\rLAB-R1234_Garderos#\e[m "
    prompt = @node.model.expects prompt
    _(prompt).must_match Garderos.prompt
  end
end
