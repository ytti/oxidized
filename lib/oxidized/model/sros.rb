module Oxidized
  module Models
    class SROS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      #
      # Nokia SR OS (TiMOS) (formerly TiMetra, Alcatel, Alcatel-Lucent).
      # Used in 7705 SAR, 7210 SAS, 7450 ESS, 7750 SR, 7950 XRS, and NSP.
      #

      comment '# '

      prompt /^([-\w.:>*]+\s?[#>]\s?)$/

      cmd :all do |cfg, cmdstring|
        new_cfg = comment "COMMAND: #{cmdstring}\n"
        cfg.gsub! /# Finished .*/, ''
        cfg.gsub! /# Generated .*/, ''
        cfg.delete! "\r"
        new_cfg << cfg.cut_both
      end

      # @!visibility private
      #
      # Show the boot options file.
      #
      cmd 'show bof' do |cfg|
        comment cfg
      end

      # @!visibility private
      #
      # Show the system information.
      #
      cmd 'show system information' do |cfg|
        # @!visibility private
        #
        # Strip uptime.
        #
        cfg.gsub! /^System Up Time.*$/, ''
        comment cfg
      end

      # @!visibility private
      #
      # Show the card state.
      #
      cmd 'show card state' do |cfg|
        comment cfg
      end

      # @!visibility private
      #
      # Show the chassis information.
      #
      cmd 'show chassis' do |cfg|
        comment cfg.lines.to_a[0..25].reject { |line| line.match /state|Time|Temperature|Status/ }.join
      end

      # @!visibility private
      #
      # Show the boot log.
      #
      cmd 'file type bootlog.txt' do |cfg|
        cfg.gsub! /[\b][\b][\b]/, "\n"
        comment cfg
      end

      # @!visibility private
      #
      # Show the running debug configuration.
      #
      cmd 'show debug' do |cfg|
        comment cfg
      end

      # @!visibility private
      #
      # Show the saved debug configuration (admin debug-save).
      #
      cmd 'file type config.dbg' do |cfg|
        comment cfg
      end

      # @!visibility private
      #
      # Show the running persistent indices.
      #
      cmd "admin display-config index\n" do |cfg|
        comment cfg
      end

      # @!visibility private
      #
      # Show the running configuration.
      #
      cmd "admin display-config\n" do |cfg|
        cfg
      end

      cfg :telnet do
        username /^Login: /
        password /^Password: /
      end

      cfg :telnet, :ssh do
        post_login 'environment no more'
        pre_logout 'logout'
      end
    end
  end
end
