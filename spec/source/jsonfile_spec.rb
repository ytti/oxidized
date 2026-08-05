require_relative '../spec_helper'
require 'oxidized/source/jsonfile'

describe Oxidized::Source::JSONFile do
  describe '#setup' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      @source = Oxidized::Source::JSONFile.new
    end

    it 'raises Oxidized::NoConfig when no config is provided' do
      # we do not want to create the config for real
      Asetus.any_instance.expects(:save)

      Oxidized.config.source.json = ''

      err = _(-> { @source.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_equal 'No source json config, edit /cfg_path/config'
    end

    it 'raises Oxidized::InvalidConfig when name is not provided' do
      Asetus.any_instance.expects(:save).never

      Oxidized.config.source.jsonfile.file = '/cfg_path/router.json'

      err = _(-> { @source.setup }).must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'map/name is a mandatory source attribute, edit /cfg_path/config'
    end

    it 'passes when name is provided' do
      Asetus.any_instance.expects(:save).never

      Oxidized.config.source.jsonfile.map.name = 'name'

      # returns without an exception
      _(@source.setup).must_be_nil
    end
  end

  describe '#load' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      Oxidized::Config.load({ home_dir: '/cfg_path/' })
      Oxidized.hooks = Oxidized::HookManager.new

      @source = Oxidized::Source::JSONFile.new
      Oxidized.config.source.jsonfile.map.name = 'name'
    end

    it 'parses decrypted GPG output that open_file returns as a String' do
      # With gpg: true, Source#open_file returns the decrypted contents as a
      # String rather than a File, so #load must not assume it can call #read
      # on the result (issue #3879).
      @source.stubs(:open_file).returns('[{"name": "router1"}, {"name": "router2"}]')

      nodes = @source.load
      _(nodes.map { |node| node[:name] }).must_equal %w[router1 router2]
    end
  end
end
