module Oxidized
  module Models
    # Represents the H3C model.
    #
    # Handles configuration retrieval and processing for H3C devices.

    class H3C < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # H3C

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^.*([<\[][\w.-]+[>\]])$/
      comment '# '

      cmd :secret do |cfg|
        cfg.gsub! /(pin verify (?:auto|)).*/, '\\1 <PIN hidden>'
        cfg.gsub! /(%\^%#.*%\^%#)/, '<secret hidden>'
        cfg
      end

      cmd :all do |cfg|
        cfg.cut_both
      end

      cfg :telnet do
        username /^Username:$/
        password /^Password:$/
      end

      cfg :telnet, :ssh do
        post_login 'screen-length disable'
        pre_logout 'quit'
      end

      cmd 'display version' do |cfg|
        cfg = cfg.each_line.reject { |l| l.match /uptime/ }.join
        cfg = cfg.each_line.reject { |l| l.match /Uptime is/ }.join
        comment cfg
      end

      cmd 'display device' do |cfg|
        comment cfg
      end

      cmd 'display current-configuration' do |cfg|
        cfg
      end
    end
  end
end
