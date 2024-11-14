module Oxidized
  module Error
    # Exception raised when no usable nodes are found.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from NoNodesFound actions.
    class NoNodesFound < OxidizedError; end
  end
end
