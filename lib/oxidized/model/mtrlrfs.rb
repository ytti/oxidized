module Oxidized
  module Models
    class Mtrlrfs < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Motorola RFS/Extreme WM

      comment  '# '

      cmd :all do |cfg|
        # @!visibility private
        # xos inserts leading \r characters and other trailing white space.
        # this deletes extraneous \r and trailing white space.
        cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
      end

      cmd 'show version' do |cfg|
        comment cfg
      end

      cmd 'show licenses' do |cfg|
        comment cfg
      end

      cmd 'show running-config'

      cfg :telnet do
        username /^login:/
        password /^\r*password:/
      end

      cfg :telnet, :ssh do
        post_login 'terminal length 0'
        pre_logout do
          send "exit\n"
          send "n\n"
        end
      end
    end
  end
end
