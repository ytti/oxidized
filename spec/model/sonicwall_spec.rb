require_relative 'model_helper'

describe 'model/SonicOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'sonicos')
  end

  it 'matches different prompts' do
    _('admin@012345> ').must_match SonicOS.prompt
    # Issue #3333
    _('admin@host-with-minus> ').must_match SonicOS.prompt
  end
end
