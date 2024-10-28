module Oxidized
  module Models
    # Represents the AxOS model.
    #
    # Handles configuration retrieval and processing for AxOS devices.

    class AxOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /(\x1b\[\?7h)?([\w.@()-]+[#]\s?)$/
      comment '! '

      cmd 'show running-config | nomore' do |cfg|
        cfg.cut_head
      end

      cmd :all do |cfg|
        cfg.cut_tail
      end

      cfg :ssh do
        pre_logout 'exit'
      end
    end
  end
end
