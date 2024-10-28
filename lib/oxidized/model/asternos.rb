module Oxidized
  module Models
    # Represents the AsterNOS model.
    #
    # Handles configuration retrieval and processing for AsterNOS devices.

    class AsterNOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^[^\$]+\$/
      comment '# '

      cmd :all do |cfg|
        cfg.each_line.to_a[1..-2].join
      end

      cmd 'show version' do |cfg|
        # @!visibility private
        # @model = Regexp.last_match(1) if cfg =~ /^Model: (\S+)/
        comment cfg
      end

      cmd "show runningconfiguration all"

      cfg :ssh do
        # @!visibility private
        # exec true
        pre_logout 'exit'
      end
    end
  end
end
