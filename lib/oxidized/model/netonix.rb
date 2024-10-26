module Oxidized
  module Models
    # Represents the Netonix model.
    #
    # Handles configuration retrieval and processing for Netonix devices.

    class Netonix < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[\w\s\(\).@_\/:-]+#/

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd 'cat config.json;echo'

      cfg :ssh do
        post_login 'cmdline'
        pre_logout 'exit'
        pre_logout 'exit'
      end
    end
  end
end
