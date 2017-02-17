class RouterOS < Oxidized::Model
  prompt /\[\w+@\S+(\s?\S+)*\]\s?>\s?$/
  comment "# "

  cmd '/system routerboard print' do |cfg|
    comment cfg
  end

  cmd '/system package update print' do |cfg|
    comment cfg
  end

  cmd '/export' do |cfg|
    cfg.gsub! /\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]/, '' # strip ANSI colours
    cfg.gsub! /\\\r\n\s+/, ''   # strip new line
    cfg = cfg.split("\n").select { |line| not line[/^\#\s\w{3}\/\d{2}\/\d{4}.*$/] }
    cfg.join("\n") + "\n"
  end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  cfg :ssh do
    exec true
  end
end
