require_relative '../spec_helper'
require 'oxidized/source/csv'

describe Oxidized::Source::CSV do
  describe '#setup' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      @source = Oxidized::Source::CSV.new
    end

    it 'raises Oxidized::NoConfig when no config is provided' do
      # we do not want to create the config for real
      Asetus.any_instance.expects(:save)

      Oxidized.config.source.csv = ''

      err = _(-> { @source.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_equal 'no source csv config, edit /cfg_path/config'
    end

    it 'raises Oxidized::InvalidConfig when name is not provided' do
      Asetus.any_instance.expects(:save).never

      Oxidized.config.source.csv.map.ip = 0

      err = _(-> { @source.setup }).must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'map/name is a mandatory source attribute, edit /cfg_path/config'
    end

    it 'passes when name is provided' do
      Asetus.any_instance.expects(:save).never

      Oxidized.config.source.csv.map.name = 1

      # returns without an exception
      _(@source.setup).must_be_nil
    end
  end
end
