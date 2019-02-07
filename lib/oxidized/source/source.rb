module Oxidized
  class Source
    class NoConfig < OxidizedError; end

    def initialize
      @map = (Oxidized.config.model_map || {})
    end

    def map_model(model)
      @map.has_key?(model) ? @map[model] : model
    end

    def node_var_interpolate(var)
      case var
      when "nil"   then nil
      when "false" then false
      when "true"  then true
      else var
      end
    end
  end
end
