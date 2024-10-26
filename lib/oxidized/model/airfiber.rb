module Oxidized
  module Models
    # Represents the Airfiber model.
    #
    # Handles configuration retrieval and processing for Airfiber devices.

    class Airfiber < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Ubiquiti Airfiber (tested with Airfiber 11FX)

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^AF[\w\.-]+#/i

      cmd :all do |cfg|
        cfg.cut_both
      end

      pre do
        cmd 'cat /tmp/system.cfg'
      end

      cfg :telnet do
        username /^[\w\W]+\slogin:\s$/
        password /^[p:P]assword:\s$/
      end

      cfg :telnet, :ssh do
        pre_logout 'exit'
      end
    end
  end
end
