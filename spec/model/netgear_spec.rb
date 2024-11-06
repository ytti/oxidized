require_relative 'model_helper'

describe 'model/Netgear' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'netgear')
  end

  it 'matches different prompts' do
    # Prompt from Model-Notes
    _('(GS748Tv4) #').must_match Netgear.prompt
    # Prompts interpreted from PR #2954
    _('(GS748Tv4)#').must_match Netgear.prompt
    _('(GS748T -+.v4)#').must_match Netgear.prompt
    # Prompt from Issue #3287
    _('10sw011# ').must_match Netgear.prompt
  end
end
