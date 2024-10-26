module Oxidized
  module Models
    # Represents the CoriantTmos model.
    #
    # Handles configuration retrieval and processing for CoriantTmos devices.

    class CoriantTmos < Oxidized::Models::Model
      using Refinements

      comment '# '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[^\s#]+#\s$/

      cmd 'show node extensive' do |cfg|
        comment cfg
      end

      cmd 'show run' do |cfg|
        cfg
      end

      cfg :telnet do
        username /^Login:\s$/
        password /^Password:\s$/
      end

      cfg :telnet, :ssh do
        pre_logout 'exit'
        post_login 'enable config terminal length 0'
      end
    end
  end
end
