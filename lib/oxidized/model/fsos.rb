module Oxidized
  module Models
    # # Fiberstore (fs.com) FSOS notes
    #
    # This has been tested against the following models and OS versions
    #
    # |Model               |OS Version and Build          |
    # |--------------------|------------------------------|
    # |S3400-48T4SP        |Version 2.0.2J Build 81736    |
    # |S3400-48T4SP        |Version 2.0.2J Build 95262    |
    # |S3400-48T6SP        |Version 2.2.0F Build 109661   |
    # |S3410-24TS-P        |S3410_FSOS 11.4(1)B74S5       |
    # |S5850-48T4Q         |Version 7.0.4.34              |
    # |S5800-48MBQ         |Version 7.0.4.21              |
    # |S5810-48TS-P        |S5810_FSOS 11.4(1)B74S8, Release(10200711)              |
    # |S5860-20SQ          |S5860_FSOS 12.4(1)B0101P1S4   |
    #
    # Back to [Model-Notes](README.md)

    # Represents the FSOS model.
    #
    # Handles configuration retrieval and processing for FSOS devices.

    class FSOS < Oxidized::Models::Model
      # @!visibility private
      # Fiberstore / fs.com
      using Refinements
      comment '! '

      # @!visibility private
      # Handle paging
      expect /^ --More--.*$/ do |data, re|
        send ' '
        data.sub re, ''
      end

      cmd :secret do |cfg|
        cfg.gsub! /(secret \w+) (\S+).*/, '\\1 <secret hidden>'
        cfg.gsub! /(password \d+) (\S+).*/, '\\1 <secret hidden>'
        cfg.gsub! /(snmp-server community \d+) (\S+).*/, '\\1 <secret hidden>'
        cfg
      end

      cmd 'show version' do |cfg|
        # @!visibility private
        # Remove uptime so the result doesn't change every time
        cfg.gsub! /.*uptime is.*\n/, ''
        cfg.gsub! /.*System uptime.*\n/, ''
        comment cfg
      end

      cmd 'show running-config' do |cfg|
        # @!visibility private
        # Remove "Building configuration..." message
        cfg.gsub! /^Building configuration.*\n/, ''
        cfg.cut_head
      end

      cfg :telnet do
        username /^Username:/
        password /^Password:/
      end

      cfg :telnet, :ssh do
        post_login 'enable'
        post_login 'terminal length 0'
        post_login 'terminal width 256'
        pre_logout 'exit'
        pre_logout 'exit'
      end
    end
  end
end
