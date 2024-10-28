module Oxidized
  module Models
    # Represents the AsyncOS model.
    #
    # Handles configuration retrieval and processing for AsyncOS devices.

    class AsyncOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # ESA prompt "(mail.example.com)> " or "mail.example.com> "

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\r*([(]?[\w. ]+[)]?[#>]\s+)$/
      comment '! '

      # @!visibility private
      # Select passphrase display option
      expect /\[\S+\]>\s/ do |data, re|
        send "3\n"
        data.sub re, ''
      end

      # @!visibility private
      # handle paging
      expect /-Press Any Key For More-+.*$/ do |data, re|
        send " "
        data.sub re, ''
      end

      cmd 'version' do |cfg|
        comment cfg
      end

      cmd 'showconfig' do |cfg|
        # @!visibility private
        # Delete hour and date which change each run
        # cfg.gsub! /\sCurrent Time: \S+\s\S+\s+\S+\s\S+\s\S+/, ' Current Time:'
        # Delete select passphrase display option
        cfg.gsub! "Choose the passphrase option:", ''
        cfg.gsub! /1. Mask passphrases \(Files with masked passphrases cannot be loaded using/, ''
        cfg.gsub! "loadconfig command)", ''
        cfg.gsub! /2. Encrypt passphrases/, ''
        cfg.gsub! /3. Plain passphrases/, ''
        cfg.gsub! /^3$/, ''
        # @!visibility private
        # Delete space
        cfg.gsub! /\n\s{25,26}/, ''
        # @!visibility private
        # Delete after line
        cfg.gsub! /([-\\\/,.\w><@]+)(\s{25,27})/, "\\1"
        # @!visibility private
        # Add a carriage return
        cfg.gsub! /([-\\\/,.\w><@]+)(\s{6})([-\\\/,.\w><@]+)/, "\\1\n\\2\\3"
        # @!visibility private
        # Delete prompt
        cfg.gsub! /^\r*([(][\w. ]+[)][#>]\s+)$/, ''
        cfg
      end

      cfg :ssh do
        pre_logout "exit"
      end
    end
  end
end
