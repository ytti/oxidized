require_relative '../spec_helper'

describe 'Model aosw' do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.asetus.cfg.debug = false
    Oxidized.setup_logger

    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_output)

    @node = Oxidized::Node.new(name:     'example.com',
                               input:    'ssh',
                               output:   'file',
                               model:    'aosw',
                               username: 'alma',
                               password: 'armud')
  end

  it "matches different prompts" do
    # Virtual controller - ArubaOS (MODEL: 515), Version 8.10.0.7 LSR
    _('AAAA-AP123456# ').must_match AOSW.prompt

    # Hardware controller- ArubaOS (MODEL: Aruba7210), Version 8.10.0.7 LSR
    # - (host) ^[mynode] – This indicates unsaved configuration.
    # - (host) *[mynode] – This indicates available crash information.
    # - (host) [mynode] – This indicates a saved configuration.
    # [mynode] indicates the "path" you are in. On my controller, it can be
    # [/], [mm] or [mynode]. you have to 'cd ..' or 'cd /' to change it, so
    # we may never encounter [/].
    # There could be other values than [/], [mm] or [mynode]
    # Now to the test prompts:
    # Controller with saved configuration
    _('(WPP-ArubaVMC) [mynode] #').must_match AOSW.prompt
    # Controller with unsaved configuration
    _('(AAAA-WLC42) ^[mynode] #').must_match AOSW.prompt
    # Controller with available crash information
    _('(AAAA-WLC42) *[mynode] #').must_match AOSW.prompt
    # Controller with crash information in path /
    _('(AAAA-WLC42) *[/] #').must_match AOSW.prompt
    # Controller with saved configuration in path mm
    _('(AAAA-WLC42) [mm] #').must_match AOSW.prompt
  end
end
