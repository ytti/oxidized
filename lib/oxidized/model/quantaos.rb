module Oxidized
  module Models
    # Represents the QuantaOS model.
    #
    # Handles configuration retrieval and processing for QuantaOS devices.

    class QuantaOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\((\w|\S)+\) (>|#)$/
      comment '! '

      cmd 'show run' do |cfg|
        cfg.each_line.select do |line|
          (not line.match /^!.*$/) &&
            (not line.match /^\((\w|\S)+\) (>|#)$/) &&
            (not line.match /^show run$/)
        end.join
      end

      cfg :telnet do
        username /^User(name)?:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        post_login do
          send "enable\n"
          cmd vars(:enable) || ""
        end
        post_login 'terminal length 0'
        pre_logout do
          send "quit\n"
          send "n\n"
        end
      end
    end
  end
end
