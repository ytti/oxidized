module Oxidized
  module Hook
    # The NoopHook class is a simple implementation of an Oxidized hook that performs
    # no operations. It serves as a placeholder or a testing tool within the Oxidized
    # framework.
    #
    # This class is useful for debugging or testing purposes, allowing users to verify
    # that hooks are being executed without introducing any side effects. It can also
    # be used as a baseline for developing more complex hooks.
    class NoopHook < Oxidized::Hook
      # Logs a message indicating that configuration
      #   validation has been triggered, but does not enforce any validation rules.
      def validate_cfg!
        log "Validate config"
      end

      # Logs the context in which the hook was invoked, but
      #   does not perform any further actions.
      #
      # @param ctx [HookContext] the context in which the hook is executed.
      # @return [void]
      def run_hook(ctx)
        log "Run hook with context: #{ctx}"
      end
    end
  end
end
