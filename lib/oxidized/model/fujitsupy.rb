module Oxidized
  module Models
    # Represents the FujitsuPY model.
    #
    # Handles configuration retrieval and processing for FujitsuPY devices.

    class FujitsuPY < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(\([\w.-]*\)\s#|^\S+#\s)$/
      comment  '! '

      cmd :all do |cfg|
        cfg.cut_both
      end

      # @!visibility private
      # 1Gbe switch
      cmd 'show version' do |cfg|
        cfg.gsub! /^(<ERROR> : 2 : format error)$/, ''
        comment cfg
      end

      # @!visibility private
      # 10Gbe switch
      cmd 'show system information' do |cfg|
        cfg.gsub! /^Current-time : [\w\s:]*$/, ''
        cfg.gsub! /^(\s{33}\^)$/, ''
        cfg.gsub! /^(% Invalid input detected at '\^' marker.)$/, ''
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg
      end

      cfg :telnet do
        username /^Username:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        post_login 'no pager'
        post_login 'terminal pager disable'
        pre_logout do
          send "quit\n"
          send "n\n"
        end
      end
    end
  end
end
