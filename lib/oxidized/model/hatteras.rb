module Oxidized
  module Models
    # Represents the Hatteras model.
    #
    # Handles configuration retrieval and processing for Hatteras devices.

    class Hatteras < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Hatteras Networks

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
      prompt /^(\r?[\w.@()-]+[#>]\s?)$/
      comment '# '

      expect /WARNING: System configuration changes will be lost when the device restarts./ do |data, re|
        send "y\r"
        data.sub re, ''
      end

      cmd :secret do |cfg|
        cfg.gsub! /^(community) \S+/, '\\1 "<configuration removed>"'
        cfg.gsub! /^(communityString) "\S+"/, '\\1 "<configuration removed>"'
        cfg.gsub! /^(key) "\S+"/, '\\1 "<secret hidden>"'
        cfg
      end

      cmd :all do |cfg|
        cfg.cut_both
      end

      cmd "show switch\r" do |cfg|
        cfg = cfg.each_line.reject do |line|
          line.match(/Switch uptime|Switch temperature|Last reset reason/) ||
            line.match(/TermCpuUtil|^\s+\^$|ERROR: Bad command/)
        end.join
        comment cfg
      end

      cmd "show card\r" do |cfg|
        cfg = cfg.each_line.reject do |line|
          line.match(/Card uptime|Card temperature|Last reset reason/) ||
            line.match(/TermCpuUtil|^\s+\^$|ERROR: Bad command/)
        end.join
        comment cfg
      end

      cmd "show sfp *\r" do |cfg|
        comment cfg
      end

      cmd "show config run\r" do |cfg|
        cfg
      end

      cfg :telnet do
        username /^Login:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        pre_logout "logout\r"
      end
    end
  end
end
