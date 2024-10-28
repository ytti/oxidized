module Oxidized
  module Models
    # Represents the OneOS model.
    #
    # Handles configuration retrieval and processing for OneOS devices.

    class OneOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([\w.@()-]+#\s?)$/
      comment  '! '

      # @!visibility private
      # example how to handle pager
      # expect /^\s--More--\s+.*$/ do |data, re|
      #  send ' '
      #  data.sub re, ''
      # end

      # @!visibility private
      # non-preferred way to handle additional PW prompt
      # expect /^[\w.]+>$/ do |data|
      #  send "enable\n"
      #  send vars(:enable) + "\n"
      #  data
      # end

      cmd :all do |cfg|
        # @!visibility private
        # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
        # cfg.gsub! /\cH+/, ''              # example how to handle pager
        cfg.cut_both
      end

      cmd :secret do |cfg|
        cfg.gsub! /^(snmp set-read-community ").*+?(".*)$/, '\\1<secret hidden>\\2'
        cfg
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show system hardware' do |cfg|
        comment cfg
      end

      cmd 'show product-info-area' do |cfg|
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg = cfg.each_line.to_a[0..-1].join
        cfg.gsub! /^Building configuration...\s*[^\n]*\n/, ''
        cfg.gsub! /^Current configuration :\s*[^\n]*\n/, ''
        cfg
      end

      cfg :telnet do
        username /^Username:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        # @!visibility private
        # preferred way to handle additional passwords
        if vars :enable
          post_login do
            send "enable\n"
            cmd vars(:enable)
          end
        end
        post_login 'term len 0'
        pre_logout 'exit'
      end
    end
  end
end
