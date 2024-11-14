module Oxidized
  module Error
    # Raised when an invalid configuration is encountered.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from InvalidConfig actions.
    class InvalidConfig < OxidizedError; end
  end
end
