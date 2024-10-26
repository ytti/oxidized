module Oxidized
  module Models
    # Represents the SpeedTouch model.
    #
    # Handles configuration retrieval and processing for SpeedTouch devices.

    class SpeedTouch < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /([\w{}=]+[>])$/
      comment '! '

      expect /login$/ do
        send "\n"
        ""
      end

      cmd ':env list' do |cfg|
        cfg.each_line.select do |line|
          (not line.match /:env list$/) &&
            (not line.match /{\w+}=>$/)
        end.join
        comment cfg
      end

      cmd ':config dump' do |cfg|
        cfg.each_line.select do |line|
          (not line.match /:config dump$/) &&
            (not line.match /{\w+}=>$/)
        end.join
        cfg
      end

      cfg :telnet do
        username /^Username : /
        password /^Password : /
      end

      cfg :telnet do
        pre_logout 'exit'
      end
    end
  end
end
