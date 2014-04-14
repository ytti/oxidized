module Oxidized
  class Output
    class NoConfig < OxidizedError; end
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
  end
end
