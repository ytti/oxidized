module Oxidized
  module Models
    # Represents the NDMS model.
    #
    # Handles configuration retrieval and processing for NDMS devices.

    class NDMS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Pull config from Zyxel Keenetic devices from version NDMS >= 2.0

      comment '! '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([\w.@()-]+[#>]\s?)/m

      cmd 'show version' do |cfg|
        cfg = cfg.each_line.to_a[1..-3].join
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg = cfg.cut_both.each_line.reject { |line| line.match /(clock date|checksum)/ }.join
        cfg
      end

      cfg :telnet do
        username /^Login:/
        password /^Password:/
        pre_logout 'exit'
      end
    end
  end
end
