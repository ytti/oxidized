module Oxidized
  class Signals
    @handlers = Hash.new { |h, k| h[k] = [] }
    class << self
      attr_accessor :handlers

      def register_signal(sig, procobj)
        # Compute short name of the signal (without SIG prefix)
        sigshortname = sig.gsub "SIG", ''
        signum = ::Signal.list[sigshortname]

        # Register the handler with OS
        ::Signal.trap signum do
          Oxidized::Signals.handle_signal(signum)
        end

        # Add the proc to the handler list for the requested signal
        @handlers[signum].push(procobj)
      end

      def handle_signal(signum)
        return unless handlers.has_key?(signum)

        @handlers[signum].each do |handler|
          handler.call
        end
      end
    end
  end
end
