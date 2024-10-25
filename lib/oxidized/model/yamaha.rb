module Oxidized
  module Models
    class Yamaha < Oxidized::Models::Model
      using Refinements

      prompt /^([\w.@()-]+[#>]\s?)$/
      comment '# '

      expect /^---more---$/ do |data, re|
        send ' '
        data.sub re, ''
      end

      # @!visibility private
      # non-preferred way to handle additional PW prompt
      # expect /^[\w.]+>$/ do |data|
      #  send "enable\n"
      #  send vars(:enable) + "\n"
      #  data
      # end

      expect /^Save new configuration/ do |data, re|
        send "N\n"
        data.sub re, ''
      end

      cmd :all do |cfg|
        # @!visibility private
        # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
        # cfg.gsub! /\cH+/, ''              # example how to handle pager
        # get rid of errors for commands that don't work on some devices
        cfg.gsub! /^Error: Invalid command name$|^\s+\^$/, ''
        cfg.cut_both
      end

      cmd 'show config' do |cfg|
        cfg.gsub! /^(# Reporting Date:\s+)(.*)$/, '\1<stripped>'
        cfg
      end

      cfg :telnet do
        password /^Password:/i
      end

      cfg :telnet, :ssh do
        # @!visibility private
        # preferred way to handle additional passwords
        post_login 'console lines infinity'
        post_login 'console columns  200'
        post_login 'console character ascii'
        post_login do
          if vars(:enable) == true
            cmd "administrator"
          elsif vars(:enable)
            cmd "administrator", /^[pP]assword:/
            cmd vars(:enable)
          end
        end
        pre_logout do
          cmd 'exit'
        end
        pre_logout 'exit'
      end
    end
  end
end
