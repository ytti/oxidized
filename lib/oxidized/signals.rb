# The Puma module serves as a namespace for the Puma web server,
# which is a concurrent HTTP server for Ruby/Rack applications.
# The Puma module houses Oxidized-specific extensions, providing additional
# functionality tailored for the Oxidized framework.
module Puma
  # The Signal class manages signal trapping for the Puma server.
  #
  # It monkey patches the standard Signal.trap method to prevent Puma from
  # overriding existing signal handlers and to avoid registering its own SIGHUP
  # handler. Instead, it allows Oxidized to manage signal handling appropriately.
  class Signal
    class << self
      # Creates an alias for the `trap` method, allowing it to be called as `os_trap`.
      alias os_trap trap

      # Registers a signal handler for the given signal.
      #
      # This method is called instead of the default Signal.trap method to
      # register a handler with Oxidized's signal management system.
      #
      # @param sig [String] the signal to trap
      # @param block [Proc] the block to execute when the signal is received
      # @return [void]
      def Signal.trap(sig, &block)
        sigshortname = sig.gsub "SIG", ''
        Oxidized::Signals.register_signal(sig, block) unless sigshortname.eql? 'HUP'
      end
    end
  end
end

module Oxidized
  # The Signals class manages signal handling for the Oxidized application.
  #
  # It allows registering custom handlers for various system signals and ensures
  # that these handlers are invoked when the signals are received.
  class Signals
    @handlers = Hash.new { |h, k| h[k] = [] }
    class << self
      # A hash that maps signals to their respective handler procs.
      #
      # @!attribute [rw] handlers
      # @return [Hash{Symbol => Array<Proc>}] a hash of signal handlers
      attr_accessor :handlers

      # Registers a signal handler for the given signal.
      #
      # This method computes the signal number for the provided signal name,
      # sets up the OS signal trap, and adds the provided proc to the handler list
      # for that signal.
      #
      # @param sig [String] the signal to trap
      # @param procobj [Proc] the proc to execute when the signal is received
      # @return [void]
      def register_signal(sig, procobj)
        # @!visibility private
        # Compute short name of the signal (without SIG prefix)
        sigshortname = sig.gsub "SIG", ''
        signum = Signal.list[sigshortname]

        # @!visibility private
        # Register the handler with OS
        Signal.trap signum do
          Oxidized::Signals.handle_signal(signum)
        end

        # @!visibility private
        # Add the proc to the handler list for the requested signal
        @handlers[signum].push(procobj)
      end

      # Handles the received signal by invoking all registered handlers for that signal.
      #
      # @param signum [Integer] the signal number that was received
      # @return [void]
      def handle_signal(signum)
        return unless handlers.has_key?(signum)

        @handlers[signum].each do |handler|
          handler.call
        end
      end
    end
  end
end
