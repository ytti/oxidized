module Oxidized
  module Models
    # Represents the OneFinity model.
    #
    # Handles configuration retrieval and processing for OneFinity devices.

    class OneFinity < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Fujitsu 1finity

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /(\r?[\w.@_()-]+[>]\s?)$/

      cmd :all do |cfg|
        cfg.each_line.to_a[1..-3].join
      end

      cmd 'show configuration | display set | nomore'

      cfg :ssh do
        pre_logout 'exit'
        exec true
      end
    end
  end
end
