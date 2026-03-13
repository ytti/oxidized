class FirewareOS < Oxidized::Model
  using Refinements

  # matched prompts:
  # [FAULT]WG<managed-by-wsm><master>>
  # WG<managed-by-wsm><master>>
  # WG<managed-by-wsm>>
  # [FAULT]WG<non-master>>
  # [FAULT]WG>
  # WG>

  prompt /^\[?\w*\]?\w*?(?:<[\w-]+>)*(#|>)\s*$/

  comment  '-- '

  cmd :all do |cfg|
    cfg.cut_both
  end

  # Handle Logon Disclaimer added in XTM 11.9.3
  expect /^I have read and accept the Logon Disclaimer message. \(yes or no\)\? $/ do |data, re|
    send "yes\n"
    data.sub re, ''
  end

  cmd 'show sysinfo' do |cfg|
    # avoid commits due to uptime
    cfg = cfg.each_line.reject { |line| line.match /(.*time.*)|(.*memory.*)|(.*cpu.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'export config to console'

  cfg :ssh do
    pre_logout 'exit'
  end
end
