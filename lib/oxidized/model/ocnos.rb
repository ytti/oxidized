module Oxidized
  module Models
    # Represents the OcNOS model.
    #
    # Handles configuration retrieval and processing for OcNOS devices.

    class OcNOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /([\w.@-]+[#>]\s?)$/
      comment '# '

      cfg :ssh do
        post_login 'terminal length 0'
        pre_logout do
          send "disable\r"
          send "logout\r"
        end
      end

      cmd :all do |cfg|
        cfg.lines.to_a[1..-2].join
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show system fru' do |cfg|
        comment cfg
      end

      cmd 'show system-information board-info' do |cfg|
        comment cfg
      end

      cmd 'show forwarding profile limit' do |cfg|
        comment cfg
      end

      cmd 'show license' do |cfg|
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg
      end
    end
  end
end
