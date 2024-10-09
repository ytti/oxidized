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
    end

    it 'returns nil when the source is not available' do
      result = Oxidized.mgr.add_source('XXX')
      _(result).must_be_nil
    end
  end
end
