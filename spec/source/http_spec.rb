require 'spec_helper'
require 'oxidized/source/http'

describe Oxidized::HTTP do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger
  end

  describe "#string_navigate" do
    h1 = {}
    h1["inventory"] = [{ "ip" => "10.10.10.10" }]
    h1["jotain"] = { "2" => "jotain" }
    it "should be able to navigate multilevel-hash" do
      http = Oxidized::HTTP.new
      http.class.must_equal Oxidized::HTTP
      http.send(:string_navigate, h1, "jotain.2").must_equal "jotain"
    end
    it "should be able to navigate multilevel-hash" do
      Oxidized::HTTP.new.send(:string_navigate, h1, "jotain.2").must_equal "jotain"
    end
    it "should be able to navigate hash/array combination" do
      Oxidized::HTTP.new.send(:string_navigate, h1, "inventory[0].ip").must_equal "10.10.10.10"
    end
    it "should return nil on non-existing string key" do
      Oxidized::HTTP.new.send(:string_navigate, h1, "jotain.3").must_equal nil
    end
    it "should return nil on non-existing array index" do
      Oxidized::HTTP.new.send(:string_navigate, h1, "inventory[3]").must_equal nil
    end
  end
end
