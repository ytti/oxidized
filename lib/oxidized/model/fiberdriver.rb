module Oxidized
  module Models
    # Represents the FiberDriver model.
    #
    # Handles configuration retrieval and processing for FiberDriver devices.

    class FiberDriver < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /\w+#/
      comment "! "

      cmd :all do |cfg|
        cfg.cut_both
      end
      cmd 'show inventory' do |cfg|
        comment cfg
      end

      cmd "show running-config" do |cfg|
        cfg.each_line.to_a[3..-1].join
        cfg.gsub! /^Building configuration.*$/, ''
        cfg.gsub! /^Current configuration:.*$$/, ''
        cfg.gsub! /^! Configuration (saved|generated) on .*$/, ''
        cfg
      end

      cfg :ssh do
        post_login 'terminal length 0'
        post_login 'terminal width 512'
        pre_logout 'exit'
      end
    end
  end
end
