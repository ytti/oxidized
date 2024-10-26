module Oxidized
  module Models
    # # Arista EOS Configuration
    #
    # By default, EOS requires the `keyboard-interactive` SSH authentication method for a successful SSH login. To add support for this method to your Oxidized configuration, see the [SSH Auth Methods](../Configuration.md#ssh-auth-methods) directive.
    #
    # It is also possible to modify the EOS configuration to accept the `password` method which Oxidized presents by default. To do so, the following configuration statement can be used:
    #
    # ```text
    # management ssh
    #    authentication mode password
    # ```
    #
    # Back to [Model-Notes](README.md)

    # Represents the EOS model.
    #
    # Handles configuration retrieval and processing for EOS devices.

    class EOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Arista EOS model #

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^.+[#>]$/

      comment  '! '

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd :secret do |cfg|
        cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
        cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
        cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
        cfg.gsub! /^(enable (?:secret|password)).*/, '\\1 <configuration removed>'
        cfg.gsub! /^(service unsupported-transceiver).*/, '\\1 <license key removed>'
        cfg.gsub! /^(tacacs-server key \d+).*/, '\\1 <configuration removed>'
        cfg.gsub! /^(radius-server .+ key \d) \S+/, '\\1 <radius secret hidden>'
        cfg.gsub! /( {6}key) (\h+ 7) (\h+).*/, '\\1 <secret hidden>'
        cfg.gsub! /(localized|auth (md5|sha\d{0,3})|priv (des|aes\d{0,3})) \S+/, '\\1 <secret hidden>'
        cfg
      end

      cmd 'show inventory | no-more' do |cfg|
        comment cfg
      end

      cmd 'show running-config | no-more | exclude ! Time:' do |cfg|
        cfg
      end

      cfg :telnet, :ssh do
        if vars :enable
          post_login do
            send "enable\n"
            # @!visibility private
            # Interpret enable: true as meaning we won't be prompted for a password
            unless vars(:enable).is_a? TrueClass
              expect /[pP]assword:\s?$/
              send vars(:enable) + "\n"
            end
            expect /^.+[#>]\s?$/
          end
          post_login 'terminal length 0'
        end
        pre_logout 'exit'
      end
    end
  end
end
