class RouterOS < Oxidized::Model
  using Refinements

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

  cmd '/system routerboard print' do |cfg|
    cfg = cfg.each_line.grep(/(model|firmware-type|current-firmware|serial-number):/).join
    comment cfg
  end

  cmd '/system package update print' do |cfg|
    version_line = cfg.each_line.grep(/installed-version:\s|current-version:\s/)[0]
    @ros_version = /([0-9])/.match(version_line)[0].to_i
    comment version_line
  end

  cmd '/system history print without-paging' do |cfg|
    comment cfg
  end

  post do
    Oxidized.logger.debug "lib/oxidized/model/routeros.rb: running /export for routeros version #{@ros_version}"
    run_cmd = if vars(:remove_secret)
                '/export hide-sensitive'
              elsif (not @ros_version.nil?) && (@ros_version >= 7)
                '/export show-sensitive'
              else
                '/export'
              end
    cmd run_cmd do |cfg|
      cfg.gsub! /\\\r?\n\s+/, '' # strip new line
      cfg.gsub! /# inactive time\r\n/, '' # Remove time based system comment
      cfg.gsub! /# received packet from \S+ bad format\r\n/, '' # Remove intermittent VRRP/CARP collision comment
      cfg.gsub! /# poe-out status: short_circuit\r\n/, '' # Remove intermittent POE short_circuit comment
      cfg.gsub! /# Firmware upgraded successfully, please reboot for changes to take effect!\r\n/, '' # Remove transient firmware upgrade comment
      cfg.gsub! /# \S+ not ready\r\n/, '' # Remove intermittent $interface not ready comment
      cfg = cfg.split("\n").reject { |line| line[/^#\s\w{3}\/\d{2}\/\d{4}\s\d{2}:\d{2}:\d{2}.*$/] || line[/^#\s\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}.*$/] } # Remove date time and 'by RouterOS' comment
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
