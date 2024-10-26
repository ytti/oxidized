module Oxidized
  module Models
    # Represents the UCS model.
    #
    # Handles configuration retrieval and processing for UCS devices.

    class UCS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(\r?[\w.@_()-]+[#]\s?)$/
      comment '! '

      cmd 'show version brief' do |cfg|
        comment cfg
      end

      cmd 'show chassis detail' do |cfg|
        comment cfg
      end

      cmd 'show fabric-interconnect detail' do |cfg|
        comment cfg
      end

      cmd 'show configuration all | no-more' do |cfg|
        cfg
      end

      cfg :ssh, :telnet do
        post_login 'terminal length 0'
        pre_logout 'exit'
      end

      cfg :telnet do
        username /^login:/
        password /^Password:/
      end
    end
  end
end
