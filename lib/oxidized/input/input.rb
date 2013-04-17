module Oxidized
  class Input
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
  end
end
