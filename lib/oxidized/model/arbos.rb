module Oxidized
  module Models
    # # Arbor Networks ArbOS notes
    #
    # If you are running ArbOS version 7 or lower then you may need to update the model to remove `exec true`:
    #
    # ```ruby
    #   cfg :ssh do
    #     pre_logout 'exit'
    #   end
    # ```
    #
    # Back to [Model-Notes](README.md)

    class ARBOS < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Arbor OS model #

      prompt /^[\S\s]+\n([\w.@-]+[:\/#>]+)\s?$/
      comment '# '

      cmd 'system hardware' do |cfg|
        cfg.gsub! /^Boot time:\s.+/, '' # Remove boot timer
        cfg.gsub! /^Load averages:\s.+/, '' # Remove CPU load info
        cfg = cfg.each_line.to_a[2..-1].join
        comment cfg
      end

      cmd 'system version' do |cfg|
        comment cfg
      end

      cmd 'config show' do |cfg|
        cfg
      end

      cfg :ssh do
        exec true
        pre_logout 'exit'
      end
    end
  end
end
