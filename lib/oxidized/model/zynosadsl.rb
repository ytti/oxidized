module Oxidized
  module Models
    # Represents the ZyNOSADSL model.
    #
    # Handles configuration retrieval and processing for ZyNOSADSL devices.

    class ZyNOSADSL < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Used in Zyxel ADSL, such as AAM1212-51

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^.*>\s?$/
      comment ';; '

      cmd 'config show all nopause'

      cfg :telnet do
        password /^Password:/i
      end
    end
  end
end
