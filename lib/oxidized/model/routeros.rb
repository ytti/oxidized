class RouterOS < Oxidized::Model
  prompt /\[\w+@\S+(\s+\S+)*\]\s?>\s?$/
  comment "# "

  cmd :all do |cfg|
    cfg.gsub! /\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[m|K]/, '' # strip ANSI colours
    if screenscrape
      cfg = cfg.cut_both
      cfg.gsub! /^\r+(.+)/, '\1'
      cfg.gsub! /([^\r]*)\r+$/, '\1'
    end
    cfg
  end

  cmd '/system routerboard print without-paging' do |cfg|
    comment cfg
  end

  cmd '/system package update print without-paging' do |cfg|
    comment cfg
  end

  cmd '/system history print without-paging' do |cfg|
    comment cfg
  end

  post do
    run_cmd = vars(:remove_secret) ? '/export hide-sensitive' : '/export'
    cmd run_cmd do |cfg|
      cfg.gsub! /\\\r?\n\s+/, '' # strip new line
      cfg.gsub! /# inactive time\r\n/, '' # Remove time based system comment
      cfg.gsub! /# received packet from \S+ bad format\r\n/, '' # Remove intermittent VRRP/CARP collision comment
      cfg = cfg.split("\n").reject { |line| line[/^#\s\w{3}\/\d{2}\/\d{4}.*$/] }
      cfg.join("\n") + "\n"
    end
  end

  cfg :telnet do
    username /^Login:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    pre_logout 'quit'
  end

  cfg :ssh do
    exec true
  end
end
