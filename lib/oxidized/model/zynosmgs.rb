module Oxidized
  module Models
    # Represents the ZyNOSMGS model.
    #
    # Handles configuration retrieval and processing for ZyNOSMGS devices.

    class ZyNOSMGS < Oxidized::Models::Model
      using Refinements

      # Regular expression to match the device prompt.
      PROMPT = /^(\w.*)>(.*)?$/
      # @!visibility private
      # Used in Zyxel MGS Series switches

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt PROMPT
      comment '! '

      cmd 'show version' do |cfg|
        clear_output cfg
      end

      cmd 'show running-config' do |cfg|
        clear_output cfg
      end

      cfg :telnet do
        username /^User\s?name(\(1-32 chars\))?:/i
        password /^Password(\(1-32 chars\))?:/i
      end

      cfg :telnet, :ssh do
        pre_logout 'exit'
      end

      private

      def clear_output(output)
        output.gsub PROMPT, ''
      end
    end
  end
end
