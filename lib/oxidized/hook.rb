module Oxidized
  class HookManager
    include SemanticLogger::Loggable

    class << self
      def from_config(cfg)
        mgr = new
        cfg.hooks.each do |name, h_cfg|
          h_cfg.events.each do |event|
            mgr.register event.to_sym, name, h_cfg.type, h_cfg
          end
        end
        mgr
      end
    end

    # HookContext is passed to each hook. It always carries the event name.
    # The keyword_init: true argument forces keyword-argument initialization.
    HookContext = Struct.new(
      :event, :node, :job, :commitref,
      :node_raw,   # raw source record: JSON hash, SQL row hash, CSV field array
      :binding,    # Ruby binding captured at the call site
      keyword_init: true
    )

    # RegisteredHook is a container for a Hook instance
    RegisteredHook = Struct.new(:name, :hook)

    EVENTS = %i[
      node_success
      node_fail
      post_store
      nodes_done
      source_node_transform
    ].freeze
    attr_reader :registered_hooks

    def initialize
      @registered_hooks = Hash.new { |h, k| h[k] = [] }
    end

    def register(event, name, hook_type, cfg)
      unless EVENTS.include? event
        raise ArgumentError,
              "unknown event #{event}, available: #{EVENTS.join ','}"
      end

      Oxidized.mgr.add_hook(hook_type) || raise("cannot load hook '#{hook_type}', not found")
      begin
        hook = Oxidized.mgr.hook.fetch(hook_type).new
      rescue KeyError
        raise KeyError, "cannot find hook #{hook_type.inspect}"
      end

      hook.cfg = cfg

      @registered_hooks[event] << RegisteredHook.new(name, hook)
      logger.debug "Hook #{name.inspect} registered #{hook.class} for event #{event.inspect}"
    end

    # --- Transform events ---

    # Runs source_node_transform hooks in sequence, passing the return value of
    # each hook as node_attrs to the next. Returns the final node_attrs, or nil
    # to signal that the node should be excluded.
    def source_node_transform(node:, node_raw:, binding:)
      ctx = HookContext.new(
        event:    :source_node_transform,
        node:     node,
        node_raw: node_raw,
        binding:  binding
      )
      @registered_hooks[:source_node_transform].each do |r_hook|
        ctx.node = r_hook.hook.run_hook(ctx)
      rescue StandardError => e
        logger.error "Hook #{r_hook.name} (#{r_hook.hook}) failed " \
                     "(#{e.inspect}) for event :source_node_transform"
      end
      ctx.node
    end

    # --- Fire-and-forget events ---

    def node_success(node:, job: nil)
      handle(:node_success, node: node, job: job)
    end

    def node_fail(node:, job: nil)
      handle(:node_fail, node: node, job: job)
    end

    def post_store(node:, job: nil, commitref: nil)
      handle(:post_store, node: node, job: job, commitref: commitref)
    end

    def nodes_done
      handle(:nodes_done)
    end

    private

    # Shared implementation for fire-and-forget events: runs all registered
    # hooks for the event, ignores return values, logs errors.
    def handle(event, ctx_params = {})
      ctx = HookContext.new(event: event, **ctx_params)

      @registered_hooks[event].each do |r_hook|
        r_hook.hook.run_hook(ctx)
      rescue StandardError => e
        logger.error "Hook #{r_hook.name} (#{r_hook.hook}) failed " \
                     "(#{e.inspect}) for event #{event.inspect}"
      end

      nil
    end
  end

  # Hook abstract base class
  class Hook
    include SemanticLogger::Loggable

    attr_reader :cfg

    def cfg=(cfg)
      @cfg = cfg
      validate_cfg! if respond_to? :validate_cfg!
    end

    def run_hook(_ctx)
      raise NotImplementedError
    end
  end
end
