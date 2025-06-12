require_relative '../spec_helper'
require 'oxidized/config/vars'

def vars(name, vars = {})
  vars = vars.transform_keys(&:to_s)
  klass = Class.new
  klass.instance_variable_set(:@node, get_node(vars))
  klass.extend(Oxidized::Config::Vars)
  klass.vars(name)
end

def get_node(vars = {})
  Oxidized::Node.new(name:     'example.com',
                     input:    'ssh',
                     output:   'git',
                     model:    'junos',
                     username: 'user',
                     password: 'secret',
                     group:    'foo',
                     vars:     vars)
end

describe Oxidized::Config::Vars do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.asetus.cfg.debug = false
    Oxidized.setup_logger
    Oxidized.config.groups["foo"].vars = {
      "enable" => "enable_group_foo"
    }
    Oxidized.config.groups["foo"].models["junos"].vars = {
      "enable" => "enable_group_model_junos"
    }
    Oxidized.config.models["junos"].vars = {
      "enable" => "enable_model_junos"
    }
    Oxidized.config.vars = {
      "enable" => "enable_vars"
    }
    Oxidized::Node.any_instance.stubs(:resolve_output)
  end

  describe "#vars" do
    it "returns node var" do
      _(vars("enable", enable: "enable_node")).must_equal "enable_node"
    end
    it "returns group model var on missing node var" do
      _(vars("enable")).must_equal "enable_group_model_junos"
    end
    it "returns group var on missing [node, group model] var" do
      Oxidized.config.groups["foo"].models["junos"].vars.delete("enable")
      _(vars("enable")).must_equal "enable_group_foo"
    end
    it "returns group var on missing node and nil group model var" do
      Oxidized.config.groups["foo"].models["junos"].vars["enable"] = nil
      _(vars("enable")).must_equal "enable_group_foo"
    end
    it "returns false on missingnode and false group model var" do
      Oxidized.config.groups["foo"].models["junos"].vars["enable"] = false
      _(vars("enable")).must_equal false
    end
    it "returns model var on missing [node, group model, group] var" do
      Oxidized.config.groups["foo"].models["junos"].vars.delete("enable")
      Oxidized.config.groups["foo"].vars.delete("enable")
      _(vars("enable")).must_equal "enable_model_junos"
    end
    it "returns vars var on missing [node, group model, group, model]" do
      Oxidized.config.groups["foo"].models["junos"].vars.delete("enable")
      Oxidized.config.groups["foo"].vars.delete("enable")
      Oxidized.config.models["junos"].vars.delete("enable")
      _(vars("enable")).must_equal "enable_vars"
    end
    it "returns nil on missing [node, group model, group, model, vars]" do
      Oxidized.config.groups["foo"].models["junos"].vars.delete("enable")
      Oxidized.config.groups["foo"].vars.delete("enable")
      Oxidized.config.models["junos"].vars.delete("enable")
      Oxidized.config.vars.delete("enable")
      _(vars("enable")).must_equal nil
    end
  end
end
