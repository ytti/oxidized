require_relative 'spec_helper'

describe Oxidized::Manager do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.asetus.cfg.debug = false
    Oxidized.setup_logger
  end

  describe '#add_source' do
    it 'loads a source when available' do
      Oxidized.config.source.csv.file = '/some/path'
      Oxidized.config.source.csv.map.name = '0'
      result = Oxidized.mgr.add_source('csv')
      _(result['csv']).must_equal Oxidized::Source::CSV

      Oxidized.config.source.http.url = 'http://localhost/nodes'
      Oxidized.config.source.http.map.name = 'name'
      result = Oxidized.mgr.add_source('http')
      _(result['http']).must_equal Oxidized::Source::HTTP
    end

    it 'differentiates between http classes' do
      Oxidized.config.source.http.url = 'http://localhost/nodes'
      Oxidized.config.source.http.map.name = 'name'
      result = Oxidized.mgr.add_source('http')
      _(result['http']).must_equal Oxidized::Source::HTTP

      result = Oxidized.mgr.add_input('http')
      _(result['http']).must_equal Oxidized::HTTP

      Oxidized.config.output.http.url = 'http://localhost/nodes'
      result = Oxidized.mgr.add_output('http')
      _(result['http']).must_equal Oxidized::Output::Http
    end

    it 'returns nil when the source is not available' do
      result = Oxidized.mgr.add_source('XXX')
      _(result).must_be_nil
    end
  end

  describe '#add_input' do
    it 'loads an input when available' do
      result = Oxidized.mgr.add_input('http')
      _(result['http']).must_equal Oxidized::HTTP
    end

    it 'returns nil when the input is not available' do
      result = Oxidized.mgr.add_input('XXX')
      _(result).must_be_nil
    end
  end

  describe '#add_output' do
    it 'loads http output' do
      Oxidized.config.output.http.url = 'http://localhost/nodes'
      result = Oxidized.mgr.add_output('http')
      _(result['http']).must_equal Oxidized::Output::Http
    end

    it 'loads file output' do
      Oxidized.config.output.file.directory = '/some/path'
      result = Oxidized.mgr.add_output('file')
      _(result['file']).must_equal Oxidized::Output::File
    end

    it 'returns nil when the output is not available' do
      result = Oxidized.mgr.add_output('XXX')
      _(result).must_be_nil
    end
  end

  describe '#add_model' do
    it 'loads a model when available' do
      result = Oxidized.mgr.add_model('ios')
      _(result['ios']).must_equal IOS
    end

    it 'returns nil when the model is not available' do
      result = Oxidized.mgr.add_model('XXX')
      _(result).must_be_nil
    end
  end

  describe '#add_hook' do
    it 'loads a hook when available' do
      result = Oxidized.mgr.add_hook('githubrepo')
      _(result['githubrepo']).must_equal GithubRepo
    end

    it 'returns nil when the hook is not available' do
      result = Oxidized.mgr.add_hook('XXX')
      _(result).must_be_nil
    end
  end
end
