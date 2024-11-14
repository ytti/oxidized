module Oxidized
  module Error
    # Raised when no node is found.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from NodeNotFound actions.
    class NodeNotFound < OxidizedError; end
  end
end
