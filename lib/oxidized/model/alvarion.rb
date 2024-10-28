module Oxidized
  module Models
    # Represents the Alvarion model.
    #
    # Handles configuration retrieval and processing for Alvarion devices.

    class Alvarion < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Used in Alvarion wisp equipment

      # @!visibility private
      # Run this command as an instance of Model so we can access node
      pre do
        cmd "#{node.auth[:password]}.cfg"
      end

      cfg :tftp do
      end
    end
  end
end
