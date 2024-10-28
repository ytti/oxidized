module Oxidized
  module Models
    # Represents the Voss model.
    #
    # Handles configuration retrieval and processing for Voss devices.

    class Voss < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Extreme/Avaya VSP Operating System Software(VOSS)
      # Created by danielcoxman@gmail.com
      # March 16, 2019
      # This was tested on vsp4k and vsp8k

      comment '# '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[^\s#>]+[#>]$/

      # @!visibility private
      # needed for proper formatting after post_login
      cmd('') { |cfg| comment "#{cfg}\n" }

      # @!visibility private
      # Get sys-info and remove information that changes such has temperature and power
      cmd 'show sys-info' do |cfg|
        cfg.gsub! /(^((.*)SysUpTime(.*))$)/, 'removed SysUpTime'
        cfg.gsub! /^((.*)Temperature Info :(.*\r?\n){4})/, 'removed Temperature Info and 3 more lines'
        cfg.gsub! /(^((.*)AmbientTemperature(.*):(.*))$)/, 'removed AmbientTemperature'
        cfg.gsub! /(^((.*)Last Change(.*):(.*))$)/, 'remove Last Change'
        cfg.gsub! /(^((.*)Last Statistic Reset(.*):(.*))$)/, 'removed Last Statistic Reset'
        cfg.gsub! /(^((.*)Last Vlan Change(.*):(.*))$)/, 'removed Last Vlan Change'
        cfg.gsub! /(^((.*)Temperature(.*):(.*))$)/, 'removed Temperature'
        cfg.gsub! /(^((.*)Total Power Usage(.*):(.*))$)/, 'removed Total Power Usage'
        comment "#{cfg}\n"
      end

      # @!visibility private
      # more the config rather than doing a show run
      cmd 'more config.cfg' do |cfg|
        cfg.gsub! /^[^\s#>]+[#>]$/, ''
        cfg.gsub! /^more config.cfg/, '# more config.cfg'
        cfg
      end

      cfg :telnet do
        username /Login: $/
        password /Password: $/
      end

      cfg :telnet, :ssh do
        pre_logout 'exit'
        post_login 'enable'
        post_login 'terminal more disable'
      end
    end
  end
end
