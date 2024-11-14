module Oxidized
  module Error
    # Exception raised when the prompt cannot be detected.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from PromptUndetected actions.
    class PromptUndetected < OxidizedError; end
  end
end
