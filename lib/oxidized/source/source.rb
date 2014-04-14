module Oxidized
  class Source
    class NoConfig < OxidizedError; end
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
    def initialize
      @map = (CFG.model_map or {})
    end
    def map_model model
      @map.has_key?(model) ? @map[model] : model
    end
  end
end
