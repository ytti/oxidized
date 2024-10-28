module Oxidized
  module Models
    # Represents the RAISECOM model.
    #
    # Handles configuration retrieval and processing for RAISECOM devices.

    class RAISECOM < Oxidized::Models::Model
      using Refinements

      comment '! '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /([\w.@-]+[#>]\s?)$/

      cmd 'show version' do |cfg|
        cfg.gsub! /\s(System uptime is ).*/, ' \\1 <removed>'
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg.gsub! /\s(^radius-encrypt-key ).*/, ' \\1 <removed>'
        cfg
      end

      cfg :ssh do
        post_login 'terminal page-break disable'
        pre_logout 'exit'
      end
    end
  end
end
