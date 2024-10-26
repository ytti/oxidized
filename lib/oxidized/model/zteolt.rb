module Oxidized
  module Models
    # Represents the ZTEOLT model.
    #
    # Handles configuration retrieval and processing for ZTEOLT devices.

    class ZTEOLT < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Tested with C320 and C300 olt, firware 1.2.5P3 and 2.1.0

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([\w.@()-]+[#>]\s?)$/
      comment  '! '

      cmd :all do |cfg|
        cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
        cfg.cut_both
      end

      cmd :secret do |cfg|
        cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
        cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
        cfg.gsub! /^username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
        cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
        cfg
      end

      cmd 'show version-running' do |cfg|
        comment cfg
      end

      cmd 'show patch-running' do |cfg|
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg.gsub! /^timestamp_write: .*\n/, ''
        cfg
      end

      cfg :telnet do
        username /^Username:/i
        password /^Password:/i
      end

      cfg :telnet, :ssh do
        # @!visibility private
        # preferred way to handle additional passwords
        post_login do
          if vars(:enable) == true
            cmd "enable"
          elsif vars(:enable)
            cmd "enable", /^[pP]assword:/
            cmd vars(:enable)
          end
        end
        post_login 'terminal length 0'
        pre_logout 'disable'
        pre_logout 'exit'
      end
    end
  end
end
