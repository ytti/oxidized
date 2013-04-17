module Oxidized
  class Source
    class << self
      def inherited klass
        Oxidized.mgr.loader = { :class => klass }
      end
    end
    def initialize
      @map = (CFG.model_map or {})
    end
    def map_model model
      @map.key?(model) ? @map[model] : model
    end
  end
end
