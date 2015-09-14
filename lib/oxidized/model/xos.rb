class XOS < Oxidized::Model

  # Extreme Networks XOS

  prompt /^*?[\w .-]+# $/
  comment  '# '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show diagnostics' do |cfg|
    comment cfg
  end

  cmd 'show licenses' do |cfg|
    comment cfg
  end

  cmd 'show switch'do |cfg|
    comment cfg.each_line.reject { |line| line.match /Time:/ or line.match /boot/i }.join
  end

  cmd 'show configuration'

  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  cfg :telnet, :ssh do
    post_login 'disable clipaging'
    pre_logout 'exit'
  end

end
