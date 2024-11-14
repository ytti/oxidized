module Oxidized
  module Error
    # Raised when a method is not found.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from MethodNotFound actions.
    class MethodNotFound < OxidizedError; end
  end
end
