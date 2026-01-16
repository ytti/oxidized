require_relative 'spec_helper'
require 'oxidized/job'

describe Oxidized::HookManager::HookContext do
  it "takes arguments in the specified order" do
    data = { event: "event", node: "node", job: "job", commitref: "#ABCD" }
    hc = Oxidized::HookManager::HookContext.new(data)
    _(hc.event).must_equal "event"
    _(hc.to_h).must_equal data
  end
  it "takes arguments in a different order" do
    data = { node: "node", job: "job", commitref: "#ABCD", event: "event" }
    hc = Oxidized::HookManager::HookContext.new(data)
    _(hc.event).must_equal "event"
    _(hc.to_h).must_equal data
  end
  it "takes one argument and set the other to nil" do
    hc = Oxidized::HookManager::HookContext.new(node: "node")
    _(hc.node).must_equal "node"
    _(hc.event).must_be_nil
  end
end
