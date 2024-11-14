module Oxidized
  module Error
    # Exception raised when no configuration is available.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from NoConfig actions.
    class NoConfig < OxidizedError; end
  end
end
