require_relative 'model_helper'

# This test is usually skiped, but it's very useful for debuging a specific
# model test without running all the atoms tests.
# To use it, comment out the 'skip' line below and specify the model test to be run.
# You can also set 'Oxidized.asetus.cfg.debug' to true if needed.
describe 'Test one specific model' do
  before do
    init_model_helper
    Oxidized.asetus.cfg.debug = false
    Oxidized.setup_logger

    Object.any_instance.stubs(:sleep)
  end

  it 'passes the specific model' do
    skip "this test is usualy deactivated"

    # test = ATOMS::TestOutput.new('routeros', 'CHR_7.16')
    # test = ATOMS::TestOutput.new('aoscx', 'R0X25A-6410_FL.10.10.1100')
    # test = ATOMS::TestOutput.new('ios', 'asr920_16.8.1b')
    test = ATOMS::TestOutput.new('mlnxos', 'Onyx_32.1_3-30')

    cfg = MockSsh.get_result(self, test).to_cfg
    _(cfg).must_equal test.output
  end
end
