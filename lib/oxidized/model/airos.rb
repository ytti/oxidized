module Oxidized
  module Models
    class Airos < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Ubiquiti AirOS circa 5.x

      prompt /^[^#]+# /
      comment '# '

      cmd 'cat /etc/board.info' do |cfg|
        cfg.split("\n").map { |line| "# #{line}" }.join("\n") + "\n"
      end

      cmd 'cat /etc/version' do |cfg|
        comment "airos version: #{cfg}"
      end

      cmd 'sort /tmp/system.cfg'

      cmd :secret do |cfg|
        cfg.gsub! /^(users\.\d+\.password|snmp\.community)=.+/, "# \\1=<hidden>"
        cfg
      end

      cfg :ssh do
        exec true
      end
    end
  end
end
