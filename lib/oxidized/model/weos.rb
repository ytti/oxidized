module Oxidized
  module Models
    # Represents the WEOS model.
    #
    # Handles configuration retrieval and processing for WEOS devices.

    class WEOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Westell WEOS, works with Westell 8178G, Westell 8266G

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(\s[\w.@-]+[#>]\s?)$/

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd 'show running-config' do |cfg|
        cfg
      end

      cfg :telnet do
        username /login:/
        password /assword:/
        post_login 'cli more disable'
        pre_logout 'logout'
      end
    end
  end
end
