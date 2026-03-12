require_relative '../spec_helper'
require 'tmpdir'
require 'oxidized/hook/ruby'

describe Oxidized::Hook::Ruby do
  before do
    @tmpdir = Dir.mktmpdir
    Oxidized.asetus = Asetus.new
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  def make_hook_file(content)
    path = File.join(@tmpdir, "hook.rb")
    File.write(path, content)
    path
  end

  def build_hook(file_content)
    path = make_hook_file(file_content)
    hook = Oxidized::Hook::Ruby.new
    Oxidized.config.hooks.ruby_hook.file = path
    hook.cfg = Oxidized.config.hooks.ruby_hook
    hook
  end

  it "raises ArgumentError when 'file' config key is missing" do
    hook = Oxidized::Hook::Ruby.new
    Oxidized.config.hooks.ruby_hook_empty = { type: 'ruby' }
    _(-> { hook.cfg = Oxidized.config.hooks.ruby_hook_empty }).must_raise ArgumentError
  end

  it "raises ArgumentError when file does not exist" do
    hook = Oxidized::Hook::Ruby.new
    Oxidized.config.hooks.ruby_hook_missing.file = "/nonexistent/path/hook.rb"
    _(-> { hook.cfg = Oxidized.config.hooks.ruby_hook_missing }).must_raise ArgumentError
  end

  it "dispatches to the method matching the event name" do
    hook = build_hook(<<~RUBY)
      def source_node_transform(ctx)
        ctx.node.merge(transformed: true)
      end
    RUBY

    ctx = Oxidized::HookManager::HookContext.new(
      event:      :source_node_transform,
      node: { name: "r1" }
    )
    result = hook.run_hook(ctx)
    _(result).must_equal({ name: "r1", transformed: true })
  end

  it "returns nil to exclude a node" do
    hook = build_hook(<<~RUBY)
      def source_node_transform(ctx)
        nil
      end
    RUBY

    ctx = Oxidized::HookManager::HookContext.new(
      event:      :source_node_transform,
      node: { name: "r1" }
    )
    result = hook.run_hook(ctx)
    _(result).must_be_nil
  end

  it "is silent for events the file does not define" do
    hook = build_hook("# no methods defined")

    ctx = Oxidized::HookManager::HookContext.new(
      event:      :source_node_transform,
      node: { name: "r1" }
    )
    result = hook.run_hook(ctx)
    _(result).must_be_nil
  end

  it "dispatches node_success event for fire-and-forget style" do
    hook = build_hook(<<~RUBY)
      def node_success(ctx)
        @fired = true
      end
    RUBY

    ctx = Oxidized::HookManager::HookContext.new(event: :node_success, node: "some_node")
    hook.run_hook(ctx)
    _(hook.instance_variable_get(:@fired)).must_equal true
  end
end
