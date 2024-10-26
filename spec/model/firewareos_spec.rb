require_relative '../spec_helper'

describe 'Model firewareos' do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.asetus.cfg.debug = false
    Oxidized.setup_logger

    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)

    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'firewareos')
  end

  it "matches different prompts" do
    _('[FAULT]WG<managed-by-wsm><master>>').must_match Oxidized::Models::FirewareOS.prompt
    _('WG<managed-by-wsm><master>>').must_match Oxidized::Models::FirewareOS.prompt
    _('WG<managed-by-wsm>>').must_match Oxidized::Models::FirewareOS.prompt
    _('[FAULT]WG<non-master>>').must_match Oxidized::Models::FirewareOS.prompt
    _('[FAULT]WG>').must_match Oxidized::Models::FirewareOS.prompt
    _('WG>').must_match Oxidized::Models::FirewareOS.prompt
  end
end
