require_relative 'model_helper'

describe 'model/FSOS' do
  before(:each) do
    init_model_helper
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'fsos')
  end

  it 'matches different prompts' do
    _('FS-LAB-OXI#').must_match FSOS.prompt
    _('fs-lab-oxi#').must_match FSOS.prompt
  end

  it 'runs on S3400 with FSOS 2.0.2J build 120538' do
    mockmodel = MockSsh.new('examples/device-simulation/yaml/fsos_S3400-48T4SP_2.0.2J-120538.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_equal mockmodel.oxidized_output
  end

  it 'removes secrets from FSOS 2.0.2J build 120538' do
    Oxidized.config.vars.remove_secret = true
    mockmodel = MockSsh.new('examples/device-simulation/yaml/fsos_S3400-48T4SP_2.0.2J-120538.yaml')
    Net::SSH.stubs(:start).returns mockmodel

    status, result = @node.run

    _(status).must_equal :success
    _(result.to_cfg).must_match(/<secret hidden>/)
    _(result.to_cfg).wont_match(/09341b4231/)
    _(result.to_cfg).wont_match(/040b2f2f3e474329544438545f1c544759275040/)
    _(result.to_cfg).wont_match(/040b2f2f3e474329544438545f/)
    _(result.to_cfg).wont_match(/09341b42313f535e30553d55283f4f60/)
    _(result.to_cfg).wont_match(/ public /)
    _(result.to_cfg).wont_match(/114f45314d581e/)
    _(result.to_cfg).wont_match(/77fea4aabdfafba68e490caacf31b257cbf7db15179386c47c1c68e746e5f1c2/)
    _(result.to_cfg).wont_match(/efa1f375d76194fa51a3556a97e641e61685f914d446979da50a551a4333ffd7/)
    _(result.to_cfg).wont_match(/098234092384d92384f92384/)
    _(result.to_cfg).wont_match(/0932840928a209842390/)
  end
end
