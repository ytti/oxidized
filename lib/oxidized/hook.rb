module Oxidized
  # This module contains all model classes for Hooks
  module Hook
    # Manages the registration and execution of hooks in Oxidized.
    class HookManager
      class << self
        # Creates a new instance of HookManager from a configuration object.
        #
        # @param cfg [Object] configuration object containing hooks
        # @return [HookManager] instance of HookManager configured with hooks
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
      # event in question. At least it contains the event name.
      #
      # @!attribute [rw] event
      # @return [Symbol] the name of the event
      class HookContext < OpenStruct; end

      # RegisteredHook is a container for a Hook instance.
      RegisteredHook = Struct.new(:name, :hook)

      # List of events that can trigger hooks.
      EVENTS = %i[
        node_success
        node_fail
        post_store
        nodes_done
      ].freeze

      # @!attribute [rw] registered_hooks
      # @return [Hash<Symbol, Array<RegisteredHook>>] registered hooks categorized by event
      attr_reader :registered_hooks

      # Initializes a new instance of HookManager.
      def initialize
        @registered_hooks = Hash.new { |h, k| h[k] = [] }
      end

      # Registers a hook for a specified event.
      #
      # @param event [Symbol] the event to register the hook for
      # @param name [String] the name of the hook
      # @param hook_type [String] the type of the hook
      # @param cfg [Object] configuration for the hook
      # @raise [ArgumentError] if the event is unknown
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
        Oxidized.logger.debug "Hook #{name.inspect} registered #{hook.class} for event #{event.inspect}"
      end

      # Handles the specified event, executing all registered hooks for it.
      #
      # @param event [Symbol] the event to handle
      # @param ctx_params [Hash] parameters to pass to the hook context
      def handle(event, ctx_params = {})
        ctx = HookContext.new ctx_params
        ctx.event = event

        @registered_hooks[event].each do |r_hook|
          r_hook.hook.run_hook ctx
        rescue StandardError => e
          Oxidized.logger.error "Hook #{r_hook.name} (#{r_hook.hook}) failed " \
                                "(#{e.inspect}) for event #{event.inspect}"
        end
      end
    end

    # Hook abstract base class
    class Hook
      # @!attribute [rw] cfg
      # @return [Object] configuration for the hook
      attr_reader :cfg

      # @param cfg [Object] configuration for the hook
      def cfg=(cfg)
        @cfg = cfg
        validate_cfg! if respond_to? :validate_cfg!
      end

      # Runs the hook with the provided context.
      #
      # @param _ctx [HookContext] context for the hook
      # @raise [NotImplementedError] if not implemented
      def run_hook(_ctx)
        raise NotImplementedError
      end

      # Logs a message at the specified log level.
      #
      # @param msg [String] message to log
      # @param level [Symbol] log level
      def log(msg, level = :info)
        Oxidized.logger.send(level, "#{self.class.name}: #{msg}")
      end
    end
  end
end
