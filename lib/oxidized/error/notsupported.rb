module Oxidized
  module Error
    # Raised when node output is not supported.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from NotSupported actions.
    class NotSupported < OxidizedError; end
  end
end
