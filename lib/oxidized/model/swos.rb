module Oxidized
  module Models
    # @!visibility private
    # Mikrotik SwOS (Lite)
    # Represents the SwOS model.
    #
    # Handles configuration retrieval and processing for SwOS devices.

    class SwOS < Oxidized::Models::Model
      using Refinements

      cmd '/backup.swb'
      cfg :http do
        @username = @node.auth[:username]
        @password = @node.auth[:password]
        @secure = false
      end
    end
  end
end
