class LambdaDriver < Oxidized::Model
  prompt /\w+[#>]/
  comment "! "

  expect /\s*--More--\s*$/ do |data, re|
    send ' '

    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.cut_both
  end
  cmd 'show version' do |cfg|
    cfg.gsub! /^up (.*)$/, ''
    cfg.gsub! /^Internal Temperature(.*)$/, ''
    cfg.gsub! /^Backplane Voltage(.*)$/, ''
    cfg.gsub! /^.*([0-9](\.[0-9]+)?)+V\s+:\s+([0-9](\.[0-9]+)?)+$/, ''
    comment cfg
  end

  cmd "show running-config" do |cfg|
    cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^Building configuration.*$/, ''
    cfg.gsub! /^Current configuration:.*$$/, ''
    cfg.gsub! /^! Configuration (saved|generated) on .*$/, ''
    cfg
  end

  cfg :ssh do
    post_login 'terminal length 0'
    post_login 'enable'
    pre_logout 'exit'
  end
end