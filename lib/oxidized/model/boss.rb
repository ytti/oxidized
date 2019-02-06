class Boss < Oxidized::Model
  # Extreme Baystack Operating System Software(BOSS)
  # Created by danielcoxman@gmail.com
  # May 15, 2017
  # This was tested on ers3510, ers5530, ers4850, ers5952
  # ssh and telnet were tested with banner and without

  comment  '! '

  prompt /^[^\s#>]+[#>]$/

  # Handle the banner
  # to disable the banner on BOSS the configuration parameter is "banner disabled"
  expect /Enter Ctrl-Y to begin\./ do |data, re|
    send "\cY"
    data.sub re, ''
  end

  # Handle the Failed retries since last login
  # no known way to disable other than to implement radius authentication
  expect /Press ENTER to continue/ do |data, re|
    send "\n"
    data.sub re, ''
  end

  # Handle the menu on the older BOSS example ers55xx, ers56xx
  # to disable them menu on BOSS the configuration parameter is "cmd-interface cli"
  expect /ommand Line Interface\.\.\./ do |data, re|
    send "c"
    data.sub re, ''
    send "\n"
    data.sub re, ''
  end

  # needed for proper formatting
  cmd('') { |cfg| comment "#{cfg}\n" }

  # Do a sys-info and check and see if it supports stack
  cmd 'show sys-info' do |cfg|
    @stack = true if cfg =~ /Stack/
    cfg.gsub! /(^((.*)sysUpTime(.*))$)/, 'removed sysUpTime'
    cfg.gsub! /(^((.*)sysNtpTime(.*))$)/, 'removed sysNtpTime'
    cfg.gsub! /(^((.*)sysRtcTime(.*))$)/, 'removed sysNtpTime'
    # remove timestamp
    cfg.gsub! /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} .*/, ''
    comment "#{cfg}\n"
  end

  # if a stack then collect the stacking information
  cmd 'show stack-info' do |cfg|
    if @stack
      # remove timestamp
      cfg.gsub! /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} .*/, ''
      comment "#{cfg}\n"
    end
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^show running-config/, '! show running-config'
    # remove timestamp
    cfg.gsub! /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} .*/, ''
    cfg.gsub! /^[^\s#>]+[#>]$/, ''
    cfg.gsub! /^! clock set.*/, '! removed clock set'
    cfg
  end

  cfg :telnet do
    username /Username: /
    password /Password: /
  end

  cfg :telnet, :ssh do
    pre_logout 'logout'
    post_login 'terminal length 0'
    post_login 'terminal width 132'
  end
end
