module Oxidized
  class Output
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
  end
end
