module Oxidized
  module Models
    # # Lenovo Network OS
    #
    # ## Remove unstable lines
    #
    # Some configuration lines change each time you issue the `show running-config` command. These are strings with user passwords and keys (TACACS, RADIUS, etc). In order not to create many elements in the configuration history, these changing lines can be replaced with a stub line. This is what the `remove_unstable_lines` variable is for. Configuration example:
    #
    # ```yaml
    # vars:
    #   remove_unstable_lines: true
    # ```
    #
    # Alternatively map a column for the `remove_unstable_lines` variable.
    #
    # ```yaml
    # source:
    #   csv:
    #     map:
    #       name: 0
    #       ip: 1
    #       model: 2
    #       group: 3
    #     vars_map:
    #       remove_unstable_lines: 4
    # ```
    #
    # If the value of the variable is `true`, then changing lines will be replaced with a `<unstable line hidden>` stub. Otherwise, the configuration will be saved unchanged. The default value of the variable is `false`.
    #
    # Back to [Model-Notes](README.md)

    # Represents the LenovoNOS model.
    #
    # Handles configuration retrieval and processing for LenovoNOS devices.

    class LenovoNOS < Oxidized::Models::Model
      using Refinements

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^([\w.@()-]+[#>]\s?)$/
      comment '! '

      # Adds extended comments to the configuration.
      #
      # This method appends a header and output, separated by newlines, and adds them as comments to the configuration.
      #
      # @param header [String] The header string to prepend to the output.
      # @param output [String] The configuration output to be commented.
      # @return [void]
      def comment_ext(header, output)
        data = ''
        data << header
        data << "\n"
        data << output
        data << "\n"
        comment data
      end

      cmd :all do |cfg|
        cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
        cfg.cut_both
      end

      cmd :secret do |cfg|
        cfg.gsub! /^(enable password) \S+(.*)/, '\\1 <secret hidden>\\2'
        cfg.gsub! /^(access user \S+ password) \S+(.*)/, '\\1 <secret hidden>\\2'
        cfg.gsub! /^(snmp-server \S+-community) \S+(.*)/, '\\1 <secret hidden>\\2'
        cfg.gsub! /^(tacacs-server \S+ \S+ ekey) \S+(.*)/, '\\1 <secret hidden>\\2'
        cfg.gsub! /^(ntp message-digest-key \S+ md5-ekey) \S+(.*)/, '\\1 <secret hidden>\\2'
        cfg.gsub! /(.* password )"[0-9a-f]+"(.*)/, '\\1<secret hidden>\\2'
        cfg.gsub! /(.*ekey )"[0-9a-f]+"(.*)/, '\\1<secret hidden>\\2'
        cfg
      end

      expect /^Select Command Line Interface mode.*iscli.*:/ do |data, re|
        send "iscli\n"
        data.sub re, ''
      end

      cmd 'show version' do |cfg|
        cfg = cfg.each_line.to_a

        cfg = cfg.reject { |line| line.match /^System Information at/ }
        cfg = cfg.reject { |line| line.match /^Switch has been up for/ }
        cfg = cfg.reject { |line| line.match /^Last boot:/ }
        cfg = cfg.reject { |line| line.match /^Temperature / }
        cfg = cfg.reject { |line| line.match /^Power Consumption/ }

        cfg = cfg.join
        comment_ext("=== show version ===", cfg)
      end

      cmd 'show boot' do |cfg|
        comment_ext("=== show boot ===", cfg)
      end

      cmd 'show transceiver' do |cfg|
        comment_ext("=== show transceiver ===", cfg)
      end

      cmd 'show software-key' do |cfg|
        comment_ext("=== show software-key ===", cfg)
      end

      cmd 'show running-config' do |cfg|
        cfg.gsub! /^Current configuration:[^\n]*\n/, ''
        if vars(:remove_unstable_lines) == true
          cfg.gsub! /(.* password )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
          cfg.gsub! /(.*ekey )"[0-9a-f]+"(.*)/, '\\1<unstable line hidden>\\2'
        end
        cfg
      end

      cfg :ssh do
        # @!visibility private
        # preferred way to handle additional passwords
        post_login do
          if vars(:enable) == true
            cmd "enable"
          elsif vars(:enable)
            cmd "enable", /^[pP]assword:/
            cmd vars(:enable)
          end
        end
        post_login 'terminal-length 0'
        pre_logout 'exit'
      end
    end
  end
end
