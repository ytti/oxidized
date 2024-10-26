module Oxidized
  module Models
    # Represents the CiscoNGA model.
    #
    # Handles configuration retrieval and processing for CiscoNGA devices.

    class CiscoNGA < Oxidized::Models::Model
      using Refinements

      comment '# '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /([\w.@-]+[#>]\s?)$/

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show configuration' do |cfg|
        cfg
      end

      cfg :ssh do
        post_login 'terminal length 0'
        pre_logout 'exit'
      end
    end
  end
end
