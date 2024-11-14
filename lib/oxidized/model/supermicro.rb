module Oxidized
  module Models
    # Backward compatibility shim for deprecated model `supermicro`.
    # Migrate your source from `supermicro` to `edgecos`.
    #
    # @deprecated Use `edgecos` instead

    require_relative 'edgecos'
    
    Supermicro = EdgeCOS

    Oxidized.logger.warn "Using deprecated model supermicro, use edgecos instead."

    # @!visibility private
    # Deprecated
  end
end
