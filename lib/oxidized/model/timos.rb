# Backward compatibility shim for deprecated model `timos`.
# Migrate your source from `timos` to `sros`.

require_relative 'sros'

TiMOS = SROS

Oxidized.logger.warn "Using deprecated model timos, use sros instead."

# Deprecated
