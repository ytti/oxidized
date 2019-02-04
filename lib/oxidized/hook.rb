module Oxidized
  class HookManager
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

    # HookContext is passed to each hook. It can contain anything related to the
    # event in question. At least it contains the event name
    class HookContext < OpenStruct; end

    # RegisteredHook is a container for a Hook instance
    RegisteredHook = Struct.new(:name, :hook)

    Events = %i[
      node_success
      node_fail
      post_store
      nodes_done
    ].freeze
    attr_reader :registered_hooks

    def initialize
      @registered_hooks = Hash.new { |h, k| h[k] = [] }
    end

    def register(event, name, hook_type, cfg)
      unless Events.include? event
        raise ArgumentError,
              "unknown event #{event}, available: #{Events.join ','}"
      end

      Oxidized.mgr.add_hook(hook_type) || raise("cannot load hook '#{hook_type}', not found")
      begin
        hook = Oxidized.mgr.hook.fetch(hook_type).new
      rescue KeyError
        raise KeyError, "cannot find hook #{hook_type.inspect}"
      end

      hook.cfg = cfg

      @registered_hooks[event] << RegisteredHook.new(name, hook)
      Oxidized.logger.debug "Hook #{name.inspect} registered #{hook.class} for event #{event.inspect}"
    end

    def handle(event, ctx_params = {})
      ctx = HookContext.new ctx_params
      ctx.event = event

      @registered_hooks[event].each do |r_hook|
        begin
          r_hook.hook.run_hook ctx
        rescue StandardError => e
          Oxidized.logger.error "Hook #{r_hook.name} (#{r_hook.hook}) failed " \
                                "(#{e.inspect}) for event #{event.inspect}"
        end
      end
    end
  end

  # Hook abstract base class
  class Hook
    attr_reader :cfg

    def initialize; end

    def cfg=(cfg)
      @cfg = cfg
      validate_cfg! if respond_to? :validate_cfg!
    end

    def run_hook(_ctx)
      raise NotImplementedError
    end

    def log(msg, level = :info)
      Oxidized.logger.send(level, "#{self.class.name}: #{msg}")
    end
  end
end
