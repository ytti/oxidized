class AsyncOS < Oxidized::Model
  using Refinements

  # ESA prompt "(mail.example.com)> " or "mail.example.com> "
  prompt /^\r*\(?[\w.\- ]+\)?[#>]\s+$/
  comment '! '

  # Select passphrase display option
  expect /\[\S+\]>\s/ do |data, re|
    send "3\n"
    data.sub re, ''
  end

  # handle paging
  expect /-Press Any Key For More-+.*$/ do |data, re|
    send " "
    data.sub re, ''
  end

  cmd 'version' do |cfg|
    comment cfg
  end

  cmd 'showconfig' do |cfg|
    # Delete hour and date which change each run
    # cfg.gsub! /\sCurrent Time: \S+\s\S+\s+\S+\s\S+\s\S+/, ' Current Time:'
    # Delete select passphrase display option
    cfg.gsub! "Choose the passphrase option:", ''
    cfg.gsub! /1. Mask passphrases \(Files with masked passphrases cannot be loaded using/, ''
    cfg.gsub! "loadconfig command)", ''
    cfg.gsub! /2. Encrypt passphrases/, ''
    cfg.gsub! /3. Plain passphrases/, ''
    cfg.gsub! /^3$/, ''
    # Delete space
    cfg.gsub! /\n\s{25,26}/, ''
    # Delete after line
    cfg.gsub! /([-\\\/,.\w><@]+)(\s{25,27})/, "\\1"
    # Add a carriage return
    cfg.gsub! /([-\\\/,.\w><@]+)(\s{6})([-\\\/,.\w><@]+)/, "\\1\n\\2\\3"
    # Delete prompt
    cfg.gsub! /^\r*([(][\w. ]+[)][#>]\s+)$/, ''
    cfg
  end

  cfg :ssh do
    pre_logout "exit"
  end
end
