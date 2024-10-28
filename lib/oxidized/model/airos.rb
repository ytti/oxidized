module Oxidized
  module Models
    # Represents the Airos model.
    #
    # Handles configuration retrieval and processing for Airos devices.

    class Airos < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Ubiquiti AirOS circa 5.x

      # @!method prompt(regex)
      #   Sets the prompt for the device.
      #   @param regex [Regexp] The regular expression that matches the prompt.
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
