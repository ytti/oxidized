require_relative 'model_helper'

describe 'Model PanOS_API' do
  before(:each) do
    init_model_helper
    Oxidized::Node.any_instance.stubs(:resolve_input)
  end

  def get_model(vars = {})
    node = Oxidized::Node.new(name:     'example.com',
                              ip:       '192.0.2.1',
                              input:    'http',
                              model:    'panos_api',
                              username: 'oxidized',
                              password: 'secret',
                              vars:     vars)
    @http = Oxidized::HTTP.new
    @http.connect(node)
    node.model.input = @http
    node.model
  end

  def expect_keygen
    @http.expects(:get_http).with(regexp_matches(/type=keygen/)).returns(
      '<response status="success"><result><key>APIKEY</key></result></response>'
    )
  end

  it 'backs up the running configuration without the API response wrapper' do
    model = get_model
    expect_keygen
    @http.expects(:get_http).with(
      '/api?' + URI.encode_www_form(key: 'APIKEY', type: 'op', cmd: '<show><config><running/></config></show>')
    ).returns(
      "<response status=\"success\"><result>\n  <config version=\"11.1.0\">" \
      "<devices><entry name=\"localhost.localdomain\"/></devices></config>\n</result></response>"
    )

    _(model.get.to_cfg).must_equal <<~XML
      <?xml version="1.0"?>
      <config version="11.1.0">
        <devices>
          <entry name="localhost.localdomain"/>
        </devices>
      </config>
    XML
  end

  it 'backs up the candidate configuration when panos_api_candidate is set' do
    model = get_model('panos_api_candidate' => true)
    expect_keygen
    @http.expects(:get_http).with(
      '/api?' + URI.encode_www_form(key: 'APIKEY', category: 'configuration', type: 'export')
    ).returns('<config version="11.1.0"><devices/></config>')

    _(model.get.to_cfg).must_equal <<~XML
      <?xml version="1.0"?>
      <config version="11.1.0">
        <devices/>
      </config>
    XML
  end

  it 'raises an error when keygen fails' do
    model = get_model
    @http.expects(:get_http).with(regexp_matches(/type=keygen/)).returns(
      '<response status="error"><result><msg>Invalid Credential</msg></result></response>'
    )

    err = _ { model.get }.must_raise Oxidized::OxidizedError
    _(err.message).must_equal 'Could not generate PanOS API key: Invalid Credential'
  end

  it 'raises an error when fetching the running configuration fails' do
    model = get_model
    expect_keygen
    @http.expects(:get_http).with(regexp_matches(/type=op/)).returns(
      '<response status="error" code="403"><result><msg>Type [op] not authorized for user role.</msg>' \
      '</result></response>'
    )

    err = _ { model.get }.must_raise Oxidized::OxidizedError
    _(err.message).must_equal 'Could not fetch PanOS running configuration: Type [op] not authorized for user role.'
  end
end
