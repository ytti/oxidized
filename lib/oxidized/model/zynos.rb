module Oxidized
  module Models
    # # ZynOS Configuration
    #
    # ## FTP
    #
    # FTP access is only possible as admin, other users can login but cannot pull the files.
    # For the XGS4600 series the config file is _config_ and not _config-0_
    #
    # To enable FTP backup, uncomment the following line in _oxidized/lib/oxidized/model/zynos.rb_
    # ```text
    #   # cmd 'config-0'
    # ```
    #
    # The following line in _oxidized/lib/oxidized/model/zynos.rb_ will need changing
    #
    # ```text
    #   cmd 'config-0'
    # ```
    #
    # The inclusion of an extra ftp option is also require. Within _input_ add the following
    #
    # ```yaml
    # input:
    #   ftp:
    #     passive: false
    # ```
    #
    # ## SSH/TelNet
    #
    # Below is the table from the XGS4600 CLI Reference Guide (Version 3.79~4.50 Edition 1, 07/2017)
    # Take this table with a pinch of salt, level 3 will not allow _show running-config_!
    #
    # Privilege Level | Types of commands at this privilege level
    # ----------------|-------------------------------------------
    # 0|Display basic system information.
    # 3|Display configuration or status.
    # 13|Configure features except for login accounts, SNMP user accounts, the authentication method sequence and authorization settings, multiple logins, administrator and enable passwords, and configuration information display.
    # 14|Configure login accounts, SNMP user accounts, the authentication method sequence and authorization settings, multiple logins, and administrator and enable passwords, and display configuration information.
    #
    # Oxidized can now retrieve your configuration!
    #
    # Back to [Model-Notes](README.md)

    # Represents the ZyNOS model.
    #
    # Handles configuration retrieval and processing for ZyNOS devices.

    class ZyNOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([\w.@()-<]+[#>]\s?)$/
      # @!visibility private
      # if there is something you can not identify after prompt, uncomment next line and comment previous line
      # prompt /^([\w.@()-<]+[#>]\s?).*$/

      comment '! '
      # @!visibility private
      # Used in Zyxel DSLAMs, such as SAM1316. Uncomment next line to enable ftp.
      # cmd 'config-0'

      # @!visibility private
      # replace next line control sequence with a new line
      expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
        data.gsub re, "\n"
      end

      # @!visibility private
      # replace all used vt100 control sequences
      expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
        data.gsub re, ''
      end

      # @!visibility private
      # ignore copyright motd
      expect /^(Copyright .*)\n^([\w.@()-<]+[#>]\s?)$/ do
        send '\n'
        ""
      end

      cmd :all do |cfg|
        cfg = cfg.gsub /^\r/, ''
        # @!visibility private
        # Additional filtering for elder switches sending vt100 control chars via telnet
        cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
        cfg
      end

      # @!visibility private
      # remove snmp community, username, password and admin-password
      cmd :secret do |cfg|
        cfg.gsub! /^(snmp-server get-community) \S+(.*)/, '\\1 <secret hidden> \\2'
        cfg.gsub! /^(snmp-server set-community) \S+(.*)/, '\\1 <secret hidden> \\2'
        cfg.gsub! /^(logins username) \S+(.*) (password) \S+(.*)/, '\\1 <secret hidden> \\2 \\3 <secret hidden> \\4'
        cfg.gsub! /^(admin-password) \S+(.*)/, '\\1 <secret hidden> \\2'
        cfg.gsub! /^(password) \S+(.*) (privilege \S+)/, '\\1 <secret hidden> \\2 \\3'
        cfg
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show system-information' do |cfg|
        cfg.gsub! /^([Ss]ystem up [Tt]ime\s*:)(.*)/, '\\1 <time removed>'
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        cfg = cfg.split("\n")[4..-2].join("\n")
        cfg
      end

      cfg :telnet do
        username /^User name:/i
        password /^Password:/i
      end

      cfg :telnet, :ssh do
        post_login do
          if vars(:enable) == true
            cmd "enable"
          elsif vars(:enable)
            cmd "enable", /^[pP]assword:/
            cmd vars(:enable)
          end
        end
        pre_logout 'exit'
      end
    end
  end
end
