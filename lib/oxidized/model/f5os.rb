module Oxidized
  module Models
    # @!visibility private
    # frozen_string_literal: true

    # Represents the F5OS model.
    #
    # Handles configuration retrieval and processing for F5OS devices.

    class F5OS < Oxidized::Models::Model
      # @!visibility private
      # F5OS Model #

      comment '!'

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt(/^([\w.@()-]+ ?[#>]\s+)$/)

      cmd 'show running-config'

      cfg :ssh do
        post_login do
          cmd 'paginate false'
        end
        pre_logout 'exit'
      end
    end
  end
end
