require_relative 'spec_helper'
require 'oxidized/job'

describe Oxidized::HookManager::HookContext do
  it "takes keyword arguments in the specified order" do
    hc = Oxidized::HookManager::HookContext.new(event: "event", node: "node", job: "job", commitref: "#ABCD")
    _(hc.event).must_equal "event"
    _(hc.node).must_equal "node"
    _(hc.job).must_equal "job"
    _(hc.commitref).must_equal "#ABCD"
  end

  it "takes keyword arguments in a different order" do
    hc = Oxidized::HookManager::HookContext.new(node: "node", job: "job", commitref: "#ABCD", event: "event")
    _(hc.event).must_equal "event"
    _(hc.node).must_equal "node"
  end

  it "defaults unspecified fields to nil" do
    hc = Oxidized::HookManager::HookContext.new(node: "node")
    _(hc.node).must_equal "node"
    _(hc.event).must_be_nil
  end

  it "exposes node_attrs, raw_node, and binding fields" do
    node_attrs = { name: "router1", model: "junos" }
    raw        = { "name" => "router1" }
    bnd        = binding
    hc = Oxidized::HookManager::HookContext.new(node_attrs: node_attrs, raw_node: raw, binding: bnd)
    _(hc.node_attrs).must_equal node_attrs
    _(hc.raw_node).must_equal raw
    _(hc.binding).must_equal bnd
  end
end

describe Oxidized::HookManager do
  before do
    @mgr = Oxidized::HookManager.new
  end

  it "source_node_transform chains node_attrs through hooks" do
    hook = Class.new(Oxidized::Hook) do
      def run_hook(ctx)
        ctx.node_attrs.merge(extra: "added")
      end
    end.new
    registered = Oxidized::HookManager::RegisteredHook.new("test", hook)
    @mgr.registered_hooks[:source_node_transform] << registered

    result = @mgr.source_node_transform(node_attrs: { name: "r1" }, raw_node: {}, binding: binding)
    _(result).must_equal({ name: "r1", extra: "added" })
  end

  it "source_node_transform returns nil when hook returns nil (exclude semantics)" do
    hook = Class.new(Oxidized::Hook) do
      def run_hook(_ctx)
        nil
      end
    end.new
    registered = Oxidized::HookManager::RegisteredHook.new("test", hook)
    @mgr.registered_hooks[:source_node_transform] << registered

    result = @mgr.source_node_transform(node_attrs: { name: "r1" }, raw_node: {}, binding: binding)
    _(result).must_be_nil
  end

  it "source_node_transform returns initial node_attrs when no hooks registered" do
    node_attrs = { name: "r1" }
    result = @mgr.source_node_transform(node_attrs: node_attrs, raw_node: {}, binding: binding)
    _(result).must_equal node_attrs
  end

  it "node_success is fire-and-forget and returns nil" do
    result = @mgr.node_success(node: "somenode")
    _(result).must_be_nil
  end

  it "node_success runs hooks without chaining return values" do
    fired = []
    hook = Class.new(Oxidized::Hook) do
      define_method(:run_hook) { |ctx| fired << ctx.node }
    end.new
    registered = Oxidized::HookManager::RegisteredHook.new("test", hook)
    @mgr.registered_hooks[:node_success] << registered

    @mgr.node_success(node: "router1")
    _(fired).must_equal ["router1"]
  end
end
