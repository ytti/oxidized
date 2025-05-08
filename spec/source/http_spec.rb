require_relative '../spec_helper'
require 'oxidized/source/http'

describe Oxidized::Source::HTTP do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger
  end

  describe '#setup' do
    before(:each) do
      Asetus.any_instance.expects(:load)
      Asetus.any_instance.expects(:create).returns(false)

      # Set :home_dir to make sure the OXIDIZED_HOME environment variable is not used
      Oxidized::Config.load({ home_dir: '/cfg_path/' })

      @source = Oxidized::Source::HTTP.new
    end

    it 'raises Oxidized::NoConfig when no config is provided' do
      # we do not want to create the config for real
      Asetus.any_instance.expects(:save)

      Oxidized.config.source.http = ''

      err = _(-> { @source.setup }).must_raise Oxidized::NoConfig
      _(err.message).must_equal 'No source http config, edit /cfg_path/config'
    end

    it 'raises Oxidized::InvalidConfig when url is not provided' do
      Asetus.any_instance.expects(:save).never
      Oxidized.config.source.http.secure = 'false'

      err = _(-> { @source.setup }).must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'url is a mandatory http source attribute, edit /cfg_path/config'
    end

    it 'raises Oxidized::InvalidConfig when name is not provided' do
      Asetus.any_instance.expects(:save).never
      Oxidized.config.source.http.url = 'https://localhost/'

      err = _(-> { @source.setup }).must_raise Oxidized::InvalidConfig
      _(err.message).must_equal 'map/name is a mandatory source attribute, edit /cfg_path/config'
    end

    it 'passes when url and name are provided' do
      Asetus.any_instance.expects(:save).never
      Oxidized.config.source.http.url = 'https://localhost/'
      Oxidized.config.source.http.map.name = 'name'

      _(@source.setup).must_be_nil
    end
  end

  describe "#string_navigate_object" do
    h1 = {}
    h1["inventory"] = [{ "ip" => "10.10.10.10" }]
    h1["jotain"] = { "2" => "jotain" }
    it "should be able to navigate multilevel-hash" do
      http = Oxidized::Source::HTTP.new
      _(http.class).must_equal Oxidized::Source::HTTP
      _(http.send(:string_navigate_object, h1, "jotain.2")).must_equal "jotain"
    end
    it "should be able to navigate multilevel-hash" do
      _(Oxidized::Source::HTTP.new.send(:string_navigate_object, h1, "jotain.2")).must_equal "jotain"
    end
    it "should be able to navigate hash/array combination" do
      _(Oxidized::Source::HTTP.new.send(:string_navigate_object, h1, "inventory[0].ip")).must_equal "10.10.10.10"
    end
    it "should return nil on non-existing string key" do
      _(Oxidized::Source::HTTP.new.send(:string_navigate_object, h1, "jotain.3")).must_be_nil
    end
    it "should return nil on non-existing array index" do
      _(Oxidized::Source::HTTP.new.send(:string_navigate_object, h1, "inventory[3]")).must_be_nil
    end
  end
end
