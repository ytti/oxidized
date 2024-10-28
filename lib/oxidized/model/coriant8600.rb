module Oxidized
  module Models
    # Represents the Coriant8600 model.
    #
    # Handles configuration retrieval and processing for Coriant8600 devices.

    class Coriant8600 < Oxidized::Models::Model
      using Refinements

      comment '# '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[^\s#>]+[#>]$/

      cmd 'show hw-inventory' do |cfg|
        comment cfg
      end

      cmd 'show flash' do |cfg|
        comment cfg
      end

      cmd 'show run' do |cfg|
        cfg
      end

      cfg :telnet do
        username /^user name:$/
        password /^password:$/
      end

      cfg :telnet, :ssh do
        pre_logout 'exit'
        post_login 'enable'
        post_login 'terminal more off'
      end
    end
  end
end
