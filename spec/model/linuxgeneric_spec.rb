require_relative 'model_helper'

describe 'model/LinuxGeneric' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'linuxgeneric')
  end

  it 'matches different prompts' do
    _('robert@gap:~$ ').must_match Oxidized::Models::LinuxGeneric.prompt
  end
end
