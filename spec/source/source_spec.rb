require_relative '../spec_helper'
require 'oxidized/source/source'

describe Oxidized::Source do
  describe '#map_model' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })
      yaml = %(
        juniper: junos
        !ruby/regexp /procurve/: procurve
      )
      Oxidized.config.model_map = YAML.unsafe_load(yaml)
      @source = Oxidized::Source::Source.new
    end

    it 'returns map value for existing string key' do
      _(@source.map_model('juniper')).must_equal 'junos'
    end

    it 'returns its argument for non-existing string key' do
      _(@source.map_model('ios')).must_equal 'ios'
    end

    it 'returns map value for existing regexp key' do
      _(@source.map_model('foo procurve1234 bar')).must_equal 'procurve'
    end
  end
end
