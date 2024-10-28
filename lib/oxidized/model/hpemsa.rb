module Oxidized
  module Models
    # Represents the HpeMsa model.
    #
    # Handles configuration retrieval and processing for HpeMsa devices.

    class HpeMsa < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^#\s?$/

      cmd 'show configuration'

      cfg :ssh do
        post_login 'set cli-parameters pager disabled'
        pre_logout 'exit'
      end
    end
  end
end
