class CiscoSMA < Oxidized::Model
  using Refinements

  # SMA prompt "mail.example.com> "
  prompt /^\r*([-\w. ]+\.[-\w. ]+\.[-\w. ]+[#>]\s+)$/
  comment '! '

  # Select passphrase display option
  expect /using loadconfig command\. \[Y\]>/ do |data, re|
    send "y\n"
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
    cfg.gsub! "Do you want to mask the password? Files with masked passwords cannot be loaded", ''
    cfg.gsub! /^\s+y/, ''
    # Delete space
    cfg.gsub! /\n\s{25}/, ''
    # Delete after line
    cfg.gsub! /([\/\-,.\w><@]+)(\s{27})/, "\\1"
    # Add a carriage return
    cfg.gsub! /([\/\-,.\w><@]+)(\s{6,8})([\/\-,.\w><@]+)/, "\\1\n\\2\\3"
    # Delete prompt
    cfg.gsub! /^\r*([-\w. ]+\.[-\w. ]+\.[-\w. ]+[#>]\s+)$/, ''
    cfg
  end

  cfg :ssh do
    pre_logout "exit"
  end
end
