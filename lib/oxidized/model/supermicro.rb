class Supermicro < Oxidized::Model
  comment  '! '

  # example how to handle pager
  # --- [Space] Next page, [Enter] Next line, [A] All, Others to exit ---
  expect /^---(.*)exit ---$/ do |data, re|
    send 'a'
    data.sub re, ''
  end

  cmd :secret do |cfg|
    cfg.gsub!(/password \d+ (\S+).*/, '<secret removed>')
    cfg.gsub!(/community (\S+)/, 'community <hidden>')
    cfg
  end

  cmd :all do |cfg|
     cfg.each_line.to_a[1..-2].join
  end

  cmd 'show running-config'

  cmd 'show access-list tcam-utilization' do |cfg|
    comment cfg
  end

  cmd 'show memory' do |cfg|
    comment cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show watchdog' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end

end