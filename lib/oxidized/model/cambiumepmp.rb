module Oxidized
  module Models
    # Represents the CambiumePMP model.
    #
    # Handles configuration retrieval and processing for CambiumePMP devices.

    class CambiumePMP < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Cambium ePMP Radios

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /.*>/

      cmd :all do |cfg|
        cfg.cut_both
      end

      pre do
        cmd 'config show json'
      end

      cfg :ssh do
        pre_logout 'exit'
      end
    end
  end
end
