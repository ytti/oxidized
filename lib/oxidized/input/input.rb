module Oxidized
  class Input
    RescueFail = {
      :debug => [
        Errno::ECONNREFUSED,
      ],
      :warn => [
        Timeout::Error,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::EPIPE,
      ],
    }
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
  end
end
