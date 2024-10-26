module Oxidized
  module Models
    # Represents the Siklu model.
    #
    # Handles configuration retrieval and processing for Siklu devices.

    class Siklu < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Siklu EtherHaul #

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[\^M\s]{0,}[\w\-\s\.\"]+>$/

      cmd 'copy startup-configuration display' do |cfg|
        cfg.each_line.to_a[2..2].join
      end

      cmd 'copy running-configuration display' do |cfg|
        cfg.each_line.to_a[3..-2].join
      end

      cfg :ssh do
        pre_logout 'exit'
      end
    end
  end
end
