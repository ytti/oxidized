class SikluMHTG < Oxidized::Model
  using Refinements

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
