module Oxidized
  # This module contains all model classes for errors
  module Error
    # Represents an error related to Git operations in Oxidized.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from Git-related actions.
    class GitError < OxidizedError; end
    begin
      require 'rugged'
    rescue LoadError
      raise OxidizedError, 'rugged not found: sudo gem install rugged'
    end
  end
end
