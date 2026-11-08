require_relative 'model_helper'
require 'oxidized/model/vrp'

describe 'Model VRP' do
  before(:each) do
    init_model_helper

    @model = VRP.new
    @model.input = mock('Oxidized::Input')
    @model.stubs(:vars).returns(nil)
  end

  it 'removes the "Last configuration was updated/saved" lines' do
    config = <<~CONFIG
      display current-configuration all
      !Software Version V200R024C00SPC500
      !Last configuration was updated at 2026-11-06 09:12:41+08:00 by SYSTEM automatically
      !Last configuration was saved at 2026-11-06 10:03:17+08:00 by admin
      #
      sysname switch
      #
      return
      <switch>
    CONFIG

    @model.input.stubs(:cmd).returns(config)
    cmd_block = VRP.cmds[:cmd].find { |c| c[:cmd] == 'display current-configuration all' }[:block]
    result = @model.cmd('display current-configuration all', &cmd_block)

    _(result).must_equal <<~EXPECTED
      !Software Version V200R024C00SPC500
      #
      sysname switch
      #
      return
    EXPECTED
  end
end
