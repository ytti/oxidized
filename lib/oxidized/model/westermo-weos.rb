class WestermoWeos < Oxidized::Model
  comment '# '

  #Prompt based on real device
  prompt %r{[\w\-.]+:/.*[#>]\s?$}

  #Handle paging / viewer (WeOS specific)
  expect /--More--|Space for next page/ do |data, re|
    send ' '
    data.sub re, ''
  end

  #Global cleanup
  cmd :all do |cfg|
    # remove CR
    cfg = cfg.gsub(/\r/, '')

    # remove ANSI escape sequences
    cfg = cfg.gsub(/\e\[[0-9;]*[A-Za-z]/, '')

    # remove viewer header
    cfg = cfg.gsub(/Press Ctrl-C.*?\n/, '')

    # remove paging remnants
    cfg = cfg.gsub(/--More--.*?\n/, '')

    # remove timestamp line (diff noise)
    cfg = cfg.gsub(/running-config\.cfg.*$/, '')

    # normalize
    cfg.strip
  end

  #1. System info FIRST (as comments)
  cmd 'show system-information' do |cfg|
    comment cfg
  end

  #2. Then full config
  cmd 'show running-config'

  #Sensitive data masking
  cmd :secret do |cfg|
    # password fields
    cfg.gsub!(/("password"\s*:\s*)".*?"/i, '\\1"<hidden>"')

    # generic secrets
    cfg.gsub!(/("secret"\s*:\s*)".*?"/i, '\\1"<hidden>"')

    # keys / tokens
    cfg.gsub!(/("key[^"]*"\s*:\s*)".*?"/i, '\\1"<hidden>"')

    # long IDs / base64 values
    cfg.gsub!(/(".*id"\s*:\s*)".{20,}"/i, '\\1"<hidden>"')

    cfg
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
