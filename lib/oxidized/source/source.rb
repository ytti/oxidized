module Oxidized
  class Source
    class NoConfig < OxidizedError; end
    def initialize
      @map = (CFG.model_map or {})
    end
    def map_model model
      @map.has_key?(model) ? @map[model] : model
    end
  end
end
