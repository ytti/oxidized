module Oxidized
  module Models
    # Represents the AudioCodes model.
    #
    # Handles configuration retrieval and processing for AudioCodes devices.

    class AudioCodes < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Pull config from AudioCodes Mediant devices from version > 7.0

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\r?([\w.@() -]+[#>]\s?)$/
      comment '## '

      expect /\s*--MORE--$/ do |data, re|
        send ' '

        data.sub re, ''
      end

      cmd "show running-config\r\n" do |cfg|
        cfg
      end

      cfg :ssh do
        username /^login as:\s$/
        password /^.+password:\s$/
        pre_logout "exit\r\n"
      end

      cfg :telnet do
        username /^Username:\s$/
        password /^Password:\s$/
        pre_logout 'exit'
      end
    end
  end
end
