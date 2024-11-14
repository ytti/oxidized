module Oxidized
  module Error
    # Raised when a model is not found.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from ModelNotFound actions.
    class ModelNotFound < OxidizedError; end
  end
end
