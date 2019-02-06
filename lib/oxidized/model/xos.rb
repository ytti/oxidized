class XOS < Oxidized::Model
  # Extreme Networks XOS

  prompt /^*?[\w .-]+# $/
  comment  '# '

  cmd :all do |cfg|
    # xos inserts leading \r characters and other trailing white space.
    # this deletes extraneous \r and trailing white space.
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
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

  cmd 'show switch' do |cfg|
    comment cfg.each_line.reject { |line| line.match(/Time:/) || line.match(/boot/i) }.join
  end

  cmd 'show configuration' do |cfg|
    cfg = cfg.each_line.reject { |line| line.match /^#(\s[\w -]+\s)(Configuration generated)/ }.join
    cfg
  end

  cmd 'show policy detail' do |cfg|
    comment cfg
  end

  cfg :telnet do
    username /^login:/
    password /^\r*password:/
  end

  cfg :telnet, :ssh do
    post_login do
      data = cmd 'disable clipaging session'
      match = data.match /^disable clipaging session\n\*?[\w .-]+(:\d+)? # $/m
      next if match

      cmd 'disable clipaging'
    end

    pre_logout do
      send "exit\n"
      send "n\n"
    end
  end
end
