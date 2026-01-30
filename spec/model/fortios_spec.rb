require_relative 'model_helper'

describe 'Model Fortios' do
  before(:each) do
    init_model_helper
  end

  it 'gets autoupdate versions when vars "fortios_autoupdate" is set' do
    @node = Oxidized::Node.new(name:  'example.com',
                               input: 'ssh',
                               model: 'fortios',
                               vars:  { "fortios_autoupdate" => true })

    model = YAML.load_file('spec/model/data/fortios#FortiGate-91G_7.4.7_autoupdate#custom_simulation.yaml')
    mockmodel = MockSsh.new(model)
    Net::SSH.stubs(:start).returns mockmodel
    output = File.read('spec/model/data/fortios#FortiGate-91G_7.4.7_autoupdate#custom_output.txt')

    status, result = @node.run
    _(status).must_equal :success
    _(result.to_cfg).must_equal output
  end
end
