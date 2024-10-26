module Oxidized
  module Models
    # Represents the TPLink model.
    #
    # Handles configuration retrieval and processing for TPLink devices.

    class TPLink < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # tp-link prompt

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt
      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^\r?([\w.@()-]+[#>]\s?)$/
      comment '! '

      # @!visibility private
      # handle paging
      # workaround for sometimes missing whitespaces with "\s?"
      expect /Press\s?any\s?key\s?to\s?continue\s?\(Q\s?to\s?quit\)/ do |data, re|
        send ' '
        data.sub re, ''
      end

      # @!visibility private
      # send carriage return because \n with the command is not enough
      # checks if line ends with prompt >,# or \r,\nm otherwise send \r
      expect /[^>#\r\n]$/ do |data, re|
        send "\r"
        data.sub re, ''
      end

      cmd :all do |cfg|
        # @!visibility private
        # remove unwanted paging line
        cfg.gsub! /^Press any key to contin.*/, ''
        # @!visibility private
        # normalize linefeeds
        cfg.gsub! /(\r|\r\n|\n\r)/, "\n"
        # @!visibility private
        # remove empty lines
        cfg.each_line.reject { |line| line.match /^[\r\n\s\u0000#]+$/ }.join
      end

      cmd :secret do |cfg|
        cfg.gsub! /^enable password (\S+)/, 'enable password <secret hidden>'
        cfg.gsub! /^user (\S+) password (\S+) (.*)/, 'user \1 password <secret hidden> \3'
        cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
        cfg.gsub! /secret (\d+) (\S+).*/, '<secret hidden>'
        cfg
      end

      cmd 'show system-info' do |cfg|
        cfg.gsub! /(System Time\s+-).*/, '\\1 <stripped>'
        cfg.gsub! /(Running Time\s+-).*/, '\\1 <stripped>'
        comment cfg.each_line.to_a[3..-3].join
      end

      cmd 'show running-config' do |cfg|
        lines = cfg.each_line.to_a[1..-1]
        # @!visibility private
        # cut config after "end"
        lines[0..lines.index("end\n")].join
      end

      cfg :telnet, :ssh do
        username /^User ?[nN]ame:/
        password /^\r?Password:/
      end

      def log_hex(command)
        hex_command = command.bytes.map { |b| b.to_s(16).rjust(2, '0') }.join(' ')
        Oxidized.logger.debug "Command in hex: #{hex_command}"
      end

      def send(command)
        log_hex(command)
        super  # Call the original send method
      end

      def cmd(command)
        log_hex(command)
        super  # Call the original cmd method
      end

      cfg :telnet, :ssh do
        post_login do
          if vars(:enable) == true
            cmd "enable"
          elsif vars(:enable)
            cmd vars(:enable)
          end
        end

        pre_logout do
          send "exit\r"
          send "logout\r"
        end
      end
    end
  end
end
