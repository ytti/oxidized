require_relative 'model_helper'

describe 'model/AsyncOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'asyncos')
  end

  it 'matches different prompts' do
    _('(mail.example.com)> ').must_match AsyncOS.prompt
    _('mail.example.com> ').must_match AsyncOS.prompt
    # Devices running in cluster mode (see issue #3327)
    _('(Machine hostname) ').must_match AsyncOS.prompt
  end
end
