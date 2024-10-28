module Oxidized
  module Models
    # Represents the Enterasys model.
    #
    # Handles configuration retrieval and processing for Enterasys devices.

    class Enterasys < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Enterasys B3/C3 models #

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^.+\w\((su|rw)\)->\s?$/

      comment '!'

      # @!visibility private
      # Handle paging
      expect /^--More--.*$/ do |data, re|
        send ' '
        data.sub re, ''
      end

      cmd :all do |cfg|
        cfg.each_line.to_a[2..-3].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
      end

      cmd 'show system hardware' do |cfg|
        comment cfg
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show config' do |cfg|
        cfg.gsub! /^This command shows non-default configurations only./, ''
        cfg.gsub! /^Use 'show config all' to show both default and non-default configurations./, ''
        cfg.gsub! /^!|#.*/, ''
        cfg.gsub! /^$\n/, ''

        cfg
      end

      cfg :telnet do
        username /^Username:/i
        password /^Password:/i
      end

      cfg :telnet, :ssh do
        pre_logout 'exit'
      end
    end
  end
end
