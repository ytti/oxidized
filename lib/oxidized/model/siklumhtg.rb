module Oxidized
  module Models
    # # Siklu Multihaul Terragraph Radio Line
    #
    # The Siklu Multihaul TG radios use a different command set than the other Siklu radios.
    #
    # To use this model, your source must designate the model as siklumhtg instead of siklu. It also requires that the MH-TG radio be running at least version 2.1.2.
    #
    # Back to [Model-Notes](README.md)

    class SikluMHTG < Oxidized::Models::Model
      using Refinements

      # @!visibility private
      # Siklu MultiHaul TG#
      # Requires source to define the model as SikluMHTG #

      prompt /^\r?MH-[TN]\d{3}[\@][\w]{2,8}>$/

      expect /--More--/ do |data, re|
        send ' '
        data.sub re, ''
      end

      cmd 'show startup' do |cfg|
        cfg.gsub! /[\b]|\e\[A|\e\[2K/, ''
        cfg.cut_both
      end

      cfg :ssh do
        pre_logout 'quit'
      end
    end
  end
end
