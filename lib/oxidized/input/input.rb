module Oxidized
  class Input
    RescueFail = [
      Timeout::Error,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::EPIPE,
    ]
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
  end
end
