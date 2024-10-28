module Oxidized
  module Models
    # Represents the C4CMTS model.
    #
    # Handles configuration retrieval and processing for C4CMTS devices.

    class C4CMTS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Arris C4 CMTS

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([\w.@:\/-]+[#>]\s?)$/
      comment  '! '

      cmd :all do |cfg|
        cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
      end

      cmd :secret do |cfg|
        cfg.gsub! /(.+)\s+encrypted-password\s+\w+\s+(.*)/, '\\1 <secret hidden> \\2'
        cfg.gsub! /(snmp-server community)\s+".*"\s+(.*)/, '\\1 <secret hidden> \\2'
        cfg.gsub! /(tacacs.*\s+key)\s+".*"\s+(.*)/, '\\1 <secret hidden> \\2'
        cfg.gsub! /(cable authstring)\s+\w+\s+(.*)/, '\\1 <secret hidden> \\2'
        cfg
      end

      cmd 'show factory-eeprom' do |cfg|
        comment cfg.cut_both
      end

      cmd 'show version' do |cfg|
        # @!visibility private
        # remove uptime readings at char 55 and beyond
        cfg = cfg.each_line.map { |line| line.rstrip.slice(0..54) }.join("\n") + "\n"
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg.cut_both
      end

      cfg :telnet do
        username /^Username:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        if vars :enable
          post_login do
            send "enable\n"
            send vars(:enable) + "\n"
          end
        end
        pre_logout 'exit'
      end
    end
  end
end
