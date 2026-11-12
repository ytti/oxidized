require_relative 'model_helper'
require 'oxidized/model/ftd'
require 'zip'

describe 'Model FTD' do
  before(:each) do
    init_model_helper
  end

  # Build an in-memory zip containing full_config.txt, as returned by the
  # FTD download endpoint.
  def build_config_zip(config)
    buffer = Zip::OutputStream.write_buffer do |out|
      out.put_next_entry('full_config.txt')
      out.write(config.to_json)
    end
    buffer.string
  end

  def build_exporter(http)
    FTD::ConfigExporter.new(
      http:     http,
      auth:     { username: 'user', password: 'pass' },
      headers:  {},
      settings: {
        api_endpoint:    '/api/fdm/latest',
        config_filename: 'oxidized.zip',
        polls:           3,
        poll_wait:       0
      }
    )
  end

  describe 'ConfigExporter#run' do
    it 'runs the full export workflow and returns the parsed config' do
      config = [{ 'generatedOn' => '2024', 'name' => 'example' }]

      http = mock('Oxidized::HTTP')
      http.expects(:post_http)
          .with('/api/fdm/latest/fdm/token', anything)
          .returns({ 'token_type' => 'Bearer', 'access_token' => 'abc' }.to_json)
      # delete is called before and after the export.
      http.expects(:delete_http)
          .with('/api/fdm/latest/action/configfiles/oxidized.zip')
          .twice
          .returns('')
      http.expects(:post_http)
          .with('/api/fdm/latest/action/configexport', anything)
          .returns({ 'jobHistoryUuid' => 'job-1' }.to_json)
      http.expects(:get_http)
          .with('/api/fdm/latest/jobs/configexportstatus/job-1')
          .returns({ 'status' => 'SUCCESS' }.to_json)
      http.expects(:get_http)
          .with('/api/fdm/latest/action/downloadconfigfile/oxidized.zip')
          .returns(build_config_zip(config))

      exporter = build_exporter(http)
      exporter.stubs(:sleep)

      _(exporter.run).must_equal config
    end

    it 'sets the Authorization header from the login token' do
      headers = {}
      http = mock('Oxidized::HTTP')
      http.stubs(:post_http)
          .with('/api/fdm/latest/fdm/token', anything)
          .returns({ 'token_type' => 'Bearer', 'access_token' => 'abc' }.to_json)
      http.stubs(:delete_http).returns('')

      exporter = FTD::ConfigExporter.new(
        http:     http,
        auth:     { username: 'user', password: 'pass' },
        headers:  headers,
        settings: { api_endpoint: '/api/fdm/latest', config_filename: 'oxidized.zip',
                    polls: 1, poll_wait: 0 }
      )
      exporter.send(:login)

      _(headers['Authorization']).must_equal 'Bearer abc'
    end

    it 'raises FTDError when login fails' do
      http = mock('Oxidized::HTTP')
      http.expects(:post_http)
          .with('/api/fdm/latest/fdm/token', anything)
          .raises(StandardError, 'connection refused')

      exporter = build_exporter(http)

      error = _(-> { exporter.run }).must_raise FTD::FTDError
      _(error.message).must_match(/Login failed/)
    end

    it 'raises FTDError when the export job fails' do
      http = mock('Oxidized::HTTP')
      http.stubs(:post_http)
          .with('/api/fdm/latest/fdm/token', anything)
          .returns({ 'token_type' => 'Bearer', 'access_token' => 'abc' }.to_json)
      http.stubs(:delete_http).returns('')
      http.stubs(:post_http)
          .with('/api/fdm/latest/action/configexport', anything)
          .returns({ 'jobHistoryUuid' => 'job-1' }.to_json)
      http.stubs(:get_http)
          .with('/api/fdm/latest/jobs/configexportstatus/job-1')
          .returns({ 'status' => 'FAILED', 'statusMessage' => 'boom' }.to_json)

      exporter = build_exporter(http)
      exporter.stubs(:sleep)

      error = _(-> { exporter.run }).must_raise FTD::FTDError
      _(error.message).must_match(/boom/)
    end
  end

  describe '#sort_list!' do
    it 'sorts the matching identitywrapper list in-place by id' do
      cfg = [
        {
          'type' => 'identitywrapper',
          'data' => {
            'type'      => 'geolocation',
            'locations' => [{ 'id' => '3' }, { 'id' => '1' }, { 'id' => '2' }]
          }
        }
      ]

      FTD.new.__send__(:sort_list!, cfg, 'geolocation', 'locations')

      _(cfg[0]['data']['locations']).must_equal [{ 'id' => '1' }, { 'id' => '2' }, { 'id' => '3' }]
    end

    it 'leaves non-matching wrappers untouched' do
      cfg = [
        {
          'type' => 'identitywrapper',
          'data' => {
            'type'      => 'geolocation',
            'locations' => [{ 'id' => '2' }, { 'id' => '1' }]
          }
        }
      ]

      FTD.new.__send__(:sort_list!, cfg, 'distinguishednamegroup', 'distiniguishedNames')

      _(cfg[0]['data']['locations']).must_equal [{ 'id' => '2' }, { 'id' => '1' }]
    end
  end
end
