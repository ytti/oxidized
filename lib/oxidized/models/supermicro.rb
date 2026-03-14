# Backward compatibility shim for deprecated model `supermicro`.
# Migrate your source from `supermicro` to `edgecos`.

require_relative 'edgecos'

Supermicro = EdgeCOS

logger.warn "Using deprecated model supermicro, use edgecos instead."

# Deprecated
