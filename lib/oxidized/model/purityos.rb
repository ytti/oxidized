module Oxidized
  module Models
    # Represents the PurityOS model.
    #
    # Handles configuration retrieval and processing for PurityOS devices.

    class PurityOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Pure Storage Purity OS

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /\w+@\S+(\s+\S+)*\s?>\s?$/
      comment '# '

      cmd 'pureconfig list' do |cfg|
        cfg.gsub! /^purealert flag \d+$/, ''
        cfg.gsub! /(.*VEEAM-StorageLUNSnap-[0-9a-f].*)/, ''
        cfg.gsub! /(.*VEEAM-ExportLUNSnap-[0-9A-F].*)/, ''
        # @!visibility private
        # remove empty lines
        cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
      end

      cfg :ssh do
        pty_options(term: "dumb")
        pre_logout 'exit'
      end
    end
  end
end
