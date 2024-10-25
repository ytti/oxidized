module Oxidized
  module Models
    # # OS10 Configuration
    #
    # Disable banner/motd
    #
    # ```text
    # banner login disable
    # banner motd disable
    # ```
    #
    # Add allowed commands to privilege level 4
    #
    # ```text
    # privilege exec priv-lvl 4 "show inventory"
    # privilege exec priv-lvl 4 "show inventory media"
    # privilege exec priv-lvl 4 "show running-configuration"
    # ```
    #
    # Create the user will the role sysadmin (it will see the full config, including auth info and users) and the privilege level 4
    #
    # ```text
    # username oxidized password verysecurepassword role sysadmin priv-lvl 4
    # ```
    #
    # The commands Oxidized executes are:
    #
    # 1. terminal length 0
    # 2. show inventory
    # 3. show inventory media
    # 4. show running-configuration
    #
    # Oxidized can now retrieve your configuration!
    #
    # Back to [Model-Notes](README.md)

    class OS10 < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # For switches running Dell EMC Networking OS10 #
      #
      # Tested with : Dell PowerSwitch S4148U-ON

      comment  '! '

      cmd :all do |cfg|
        cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
        cfg.each_line.to_a[2..-2].join
      end

      cmd :secret do |cfg|
        cfg.gsub! /(password )(\S+)/, '\1<secret hidden>'
        cfg
      end

      cmd 'show inventory' do |cfg|
        comment cfg
      end

      cmd 'show inventory media' do |cfg|
        comment cfg
      end

      cmd 'show running-configuration' do |cfg|
        cfg.each_line.to_a[3..-1].join
      end

      cfg :telnet do
        username /^Login:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        if vars :enable
          post_login do
            send "enable\n"
            cmd vars(:enable)
          end
        end
        post_login 'terminal length 0'
        pre_logout 'exit'
        pre_logout 'exit'
      end
    end
  end
end
