require_relative 'model_helper'

# This class is used to test the developpent of model_helper.rb
# it uses the Garderos model, as model_helper.rb was deveopped with it
describe 'Model Helper' do
  before(:each) do
    init_model_helper
    @node = MockSsh.get_node('garderos')
    @test = ATOMS::TestOutput.new('garderos', 'R7709_003_006_068')
    @mockmodel = MockSsh.new(@test.simulation)
    Net::SSH.stubs(:start).returns @mockmodel
  end

  it 'works with ssh in exec mode' do
    myssh = Net::SSH.start
    _(myssh.exec!('show system version')).must_equal \
      "show system version\ngrs-gwuz-armel/003_005_068 " \
      "(Garderos; 2021-04-30 16:19:35)\n\e[4m\rLAB-R1234_Garderos#\e[m "
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
