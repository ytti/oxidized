module Oxidized
  module Error
    # Represents an error related to Git-crypt operations in Oxidized.
    #
    # This class extends the OxidizedError and is used to handle exceptions
    # specifically arising from Git-crypt actions.
    class GitCryptError < OxidizedError; end
    begin
      require 'git'
    rescue LoadError
      raise OxidizedError, 'git not found: sudo gem install git'
    end
  end
end
