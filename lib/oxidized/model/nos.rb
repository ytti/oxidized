module Oxidized
  module Models
    # Represents the NOS model.
    #
    # Handles configuration retrieval and processing for NOS devices.

    class NOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Brocade Network Operating System

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(?:\e\[..h)?[\w.-]+# $/
      comment  '! '

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd 'show version' do |cfg|
        comment cfg.each_line.reject { |line| line.match /([Ss]ystem [Uu]p\s?[Tt]ime|[Uu]p\s?[Tt]ime is \d)/ }.join
      end

      cmd 'show inventory' do |cfg|
        comment cfg
      end

      cmd 'show license' do |cfg|
        comment cfg
      end

      cmd 'show chassis' do |cfg|
        comment cfg.each_line.reject { |line| line.match(/Time/) || line.match(/Update/) }.join
      end

      cfg 'show system' do |cfg|
        comment(cfg.each_line.reject { |line| line.match(/Time/) || line.match(/speed/) })
      end

      cmd 'show running-config | nomore'

      cfg :telnet do
        username /^.* login: /
        password /^Password:/
      end

      cfg :telnet, :ssh do
        post_login 'terminal length 0'
        # @!visibility private
        # post_login 'terminal width 0'
        pre_logout 'exit'
      end
    end
  end
end
