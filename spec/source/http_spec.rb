require_relative '../spec_helper'
require 'oxidized/source/http'

describe Oxidized::HTTP do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger
  end

  describe "#string_navigate_object" do
    h1 = {}
    h1["inventory"] = [{ "ip" => "10.10.10.10" }]
    h1["jotain"] = { "2" => "jotain" }
    it "should be able to navigate multilevel-hash" do
      http = Oxidized::HTTP.new
      _(http.class).must_equal Oxidized::HTTP
      _(http.send(:string_navigate_object, h1, "jotain.2")).must_equal "jotain"
    end
    it "should be able to navigate multilevel-hash" do
      _(Oxidized::HTTP.new.send(:string_navigate_object, h1, "jotain.2")).must_equal "jotain"
    end
    it "should be able to navigate hash/array combination" do
      _(Oxidized::HTTP.new.send(:string_navigate_object, h1, "inventory[0].ip")).must_equal "10.10.10.10"
    end
    it "should return nil on non-existing string key" do
      _(Oxidized::HTTP.new.send(:string_navigate_object, h1, "jotain.3")).must_be_nil
    end
    it "should return nil on non-existing array index" do
      _(Oxidized::HTTP.new.send(:string_navigate_object, h1, "inventory[3]")).must_be_nil
    end
  end
end
