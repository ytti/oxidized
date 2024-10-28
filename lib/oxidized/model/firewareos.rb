module Oxidized
  module Models
    # Represents the FirewareOS model.
    #
    # Handles configuration retrieval and processing for FirewareOS devices.

    class FirewareOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # matched prompts:
      # [FAULT]WG<managed-by-wsm><master>>
      # WG<managed-by-wsm><master>>
      # WG<managed-by-wsm>>
      # [FAULT]WG<non-master>>
      # [FAULT]WG>
      # WG>

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\[?\w*\]?\w*?(?:<[\w-]+>)*(#|>)\s*$/

      comment  '-- '

      cmd :all do |cfg|
        cfg.cut_both
      end

      # @!visibility private
      # Handle Logon Disclaimer added in XTM 11.9.3
      expect /^I have read and accept the Logon Disclaimer message. \(yes or no\)\? $/ do |data, re|
        send "yes\n"
        data.sub re, ''
      end

      cmd 'show sysinfo' do |cfg|
        # @!visibility private
        # avoid commits due to uptime
        cfg = cfg.each_line.reject { |line| line.match /(.*time.*)|(.*memory.*)|(.*cpu.*)/ }
        cfg = cfg.join
        comment cfg
      end

      cmd 'export config to console'

      cfg :ssh do
        pre_logout 'exit'
      end
    end
  end
end
