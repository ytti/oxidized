require_relative 'model_helper'

# This class is used to test the developpent of model_helper.rb
# it uses the Garderos model, as model_helper.rb was deveopped with it
describe 'Model Helper' do
  before(:each) do
    init_model_helper
    @node = MockSsh.get_node('garderos')
    @test = ATOMS::TestOutput.new('garderos', 'R7928_003_008_036')
    @mockmodel = MockSsh.new(@test.simulation)
    Net::SSH.stubs(:start).returns @mockmodel
  end

  it 'works with ssh in exec mode' do
    myssh = Net::SSH.start
    output = myssh.exec!('show system information')
    _(output).must_match(/^System Name: LAB-R10095\r/)
    # Unknown commands raise an Error
    _(-> { myssh.exec!('hallo') }).must_raise RuntimeError
    # Commands with \n raise an Error
    _(-> { myssh.exec!("show system version\n") }).must_raise RuntimeError
  end

  it 'works with ssh in channel mode' do
    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal @test.output
  end
end
