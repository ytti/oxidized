module Oxidized
  module Models
    # Represents the TELCO model.
    #
    # Handles configuration retrieval and processing for TELCO devices.

    class TELCO < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Telco Systems T-Marc 3306

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(\r?[\w.@_()-]+[#]\s?)$/
      comment '! '

      cmd :all do |cfg|
        cfg.each_line.to_a[2..-2].join.delete("\n")
      end

      cmd 'show running-config' do |cfg|
        cfg
      end

      cfg :ssh, :telnet do
        post_login 'terminal length 0'
        pre_logout 'exit'
      end

      cfg :telnet do
        username /^Username:/
        password /^Password:/
      end
    end
  end
end
