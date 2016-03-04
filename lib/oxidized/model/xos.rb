class XOS < Oxidized::Model

  # Extreme Networks XOS

  prompt /^*?[\w .-]+# $/
  comment  '# '

  cmd :all do |cfg|
    # xos inserts leading \r characters and other trailing white space.
    # this deletes extraneous \r and trailing white space.
    cfg.each_line.to_a[1..-2].map{|line|line.delete("\r").rstrip}.join("\n") + "\n"
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
    pre_logout do
      send "exit\n"
      send "n\n"
    end
  end

end
