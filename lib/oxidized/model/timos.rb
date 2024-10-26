module Oxidized
  module Models
    require_relative 'sros'

    # Backward compatibility shim for deprecated model `timos`.
    # Migrate your source from `timos` to `sros`.
    #
    # @deprecated Use `sros` instead.
    TiMOS = SROS

    Oxidized.logger.warn "Using deprecated model timos, use sros instead."

    # @!visibility private
    # Deprecated
  end
end
