module Oxidized
  module Models
    # # Comware Configuration
    #
    # If you find 3Com Comware devices aren't being backed up this may be due to prompt detection not matching because a previous login message is disabled after the first prompt.
    #
    # You can disable this on the devices themselves by running this command:
    #
    # ```text
    # info-center source default channel 1 log state off debug state off
    # ```
    #
    # [Reference](https://github.com/ytti/oxidized/issues/1171)
    #
    # Back to [Model-Notes](README.md)

    # Represents the Comware model.
    #
    # Handles configuration retrieval and processing for Comware devices.

    class Comware < Oxidized::Models::Model
      # @!visibility private
      # HP (A-series)/H3C/3Com Comware
      using Refinements

      # @!visibility private
      # sometimes the prompt might have a leading nul or trailing ASCII Bell (^G)

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\0*(<[\w.-]+>).?$/
      comment '# '

      # @!visibility private
      # example how to handle pager
      # expect /^\s*---- More ----$/ do |data, re|
      #  send ' '
      #  data.sub re, ''
      # end

      cmd :all do |cfg|
        # @!visibility private
        # cfg.gsub! /^.*\e\[42D/, ''        # example how to handle pager
        # skip rogue ^M
        cfg = cfg.delete "\r"
        cfg.cut_both
      end

      cmd :secret do |cfg|
        cfg.gsub! /^( snmp-agent community).*/, '\\1 <configuration removed>'
        cfg.gsub! /^( password hash).*/, '\\1 <configuration removed>'
        cfg.gsub! /^( password cipher).*/, '\\1 <configuration removed>'
        cfg
      end

      cfg :telnet do
        username /^(Username|[Ll]ogin):/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        # @!visibility private
        # handle enable passwords
        post_login do
          if vars(:enable) == true
            cmd "super"
          elsif vars(:enable)
            cmd "super", /^\s?[pP]assword:/
            cmd vars(:enable)
          end
        end
        # @!visibility private
        # enable command-line mode on SMB comware switches (HP V1910, V1920)
        # autodetection is hard, because the 'summary' command is paged, and
        # the pager cannot be disabled before _cmdline-mode on.
        if vars :comware_cmdline
          post_login do
            # @!visibility private
            # HP V1910, V1920
            cmd '_cmdline-mode on', /(#{@node.prompt}|Continue)/
            cmd 'y', /(#{@node.prompt}|input password)/
            cmd vars(:comware_cmdline)

            # @!visibility private
            # HP V1950 r2432P06
            cmd 'xtd-cli-mode on', /(#{@node.prompt}|Continue)/
            cmd 'y', /(#{@node.prompt}|input password)/
            cmd vars(:comware_cmdline)

            # @!visibility private
            # HP V1950 OS r3208 (v7.1)
            # HPE Office Connect 1950
            cmd 'xtd-cli-mode', /(#{@node.prompt}|Continue|Switch)/
            cmd 'y', /(#{@node.prompt}|input password|Password:)/
            cmd vars(:comware_cmdline)
          end
        end

        post_login 'screen-length disable'
        post_login 'undo terminal monitor'
        pre_logout 'quit'
      end

      cmd 'display version' do |cfg|
        cfg = cfg.each_line.reject { |l| l.match /uptime/i }.join
        comment cfg
      end

      cmd 'display device' do |cfg|
        comment cfg
      end

      cmd 'display device manuinfo' do |cfg|
        cfg = cfg.each_line.reject { |l| l.match 'FF'.hex.chr }.join
        comment cfg
      end

      cmd 'display current-configuration' do |cfg|
        cfg
      end
    end
  end
end
