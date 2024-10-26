module Oxidized
  module Models
    # Represents the ML66 model.
    #
    # Handles configuration retrieval and processing for ML66 devices.

    class ML66 < Oxidized::Models::Model
      comment '! '

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /.*#/

      expect /User:.*$/ do |data, re|
        send "admin_user\n"
        send "#{@node.auth[:password]}\n"
        data.sub re, ''
      end

      cmd 'show version' do |cfg|
        cfg.gsub! "Uptime", ''
        comment cfg
      end

      cmd 'show inventory hw all' do |cfg|
        comment cfg
      end

      cmd 'show inventory sw all' do |cfg|
        comment cfg
      end

      cmd 'show license status all' do |cfg|
        comment cfg
      end

      cmd 'show running-config'

      cfg :ssh do
        pre_logout 'logout'
      end
    end
  end
end
