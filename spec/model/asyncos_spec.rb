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
    # Issue #3327
    _('(Machine xx-xx-x1xx1-xxxx-xxxx.xxxx.xxxxx.example.xxx)> ').must_match AsyncOS.prompt
  end
end
