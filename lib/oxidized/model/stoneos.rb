module Oxidized
  module Models
    # Represents the StoneOS model.
    #
    # Handles configuration retrieval and processing for StoneOS devices.

    class StoneOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Hillstone Networks StoneOS software

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\r?[\w.()-]+~?[#>](\s)?$/
      comment '# '

      expect /^\s.*--More--.*$/ do |data, re|
        send ' '
        data.sub re, ''
      end

      cmd :all do |cfg|
        cfg.gsub! /+.*+/, '' # Linebreak handling
        cfg.cut_both
      end

      cmd 'show configuration running' do |cfg|
        cfg.gsub! /^Building configuration.*$/, ''
      end

      cmd 'show version' do |cfg|
        cfg.gsub! /^Uptime is .*$/, ''
        comment cfg
      end

      cfg :telnet do
        username(/^login:/)
        password(/^Password:/)
      end

      cfg :telnet, :ssh do
        post_login 'terminal length 256'
        post_login 'terminal width 512'
        pre_logout 'exit'
      end
    end
  end
end
