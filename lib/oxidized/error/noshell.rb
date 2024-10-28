module Oxidized
  module Error
    # NoShell
    #
    # This error class is raised when a shell environment is not available
    # for the operation being performed in Oxidized.
    class NoShell < OxidizedError; end
  end
end
