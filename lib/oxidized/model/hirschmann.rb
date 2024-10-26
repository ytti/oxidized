module Oxidized
  module Models
    # Represents the Hirschmann model.
    #
    # Handles configuration retrieval and processing for Hirschmann devices.

    class Hirschmann < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[(\w\s)]+\s[>|#]+?$/

      comment '## '

      # @!visibility private
      # Handle pager
      expect /^--More--.*$/ do |data, re|
        send 'a'
        data.sub re, ''
      end

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd 'show sysinfo' do |cfg|
        cfg.gsub! /^System Up Time.*\n/, ""
        cfg.gsub! /^System Date and Time.*\n/, ""
        cfg.gsub! /^CPU Utilization.*\n/, ""
        cfg.gsub! /^Memory.*\n/, ""
        cfg.gsub! /^Average CPU Utilization.*\n/, ""
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg.gsub! /^users.*\n/, ""
        cfg
      end

      cfg :telnet do
        username /^User:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        post_login 'enable'
        pre_logout 'logout'
      end
    end
  end
end
