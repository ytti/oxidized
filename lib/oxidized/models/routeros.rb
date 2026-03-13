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
    cfg.lines.map { |line| line.rstrip }.join("\n") + "\n" # strip trailing whitespace
  end

  cmd '/system resource print' do |cfg|
    cfg = cfg.each_line.grep(/(version|factory-software|total-memory|cpu|cpu-count|total-hdd-space|architecture-name|board-name|platform):/).join
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
    logger.debug "Running /export for routeros version #{@ros_version}"
    run_cmd = if vars(:remove_secret)
                '/export hide-sensitive'
              elsif (not @ros_version.nil?) && (@ros_version >= 7)
                '/export show-sensitive'
              else
                '/export'
              end
    cmd run_cmd do |cfg|
      cfg.gsub! /\\\r?\n\s+/, '' # strip new line
      cfg.gsub! "# inactive time\r\n", '' # Remove time based system comment
      cfg.gsub! /# received packet from \S+ bad format\r\n/, '' # Remove intermittent VRRP/CARP collision comment
      cfg.gsub! "# poe-out status: short_circuit\r\n", '' # Remove intermittent POE short_circuit comment
      cfg.gsub! "# Firmware upgraded successfully, please reboot for changes to take effect!\r\n", '' # Remove transient firmware upgrade comment
      cfg.gsub! /# \S+ not ready\r\n/, '' # Remove intermittent $interface not ready comment
      cfg.gsub! /# .+ please restart the device in order to apply the new setting\r\n/, '' # Remove intermittent restart needed comment. (e.g. for ipv6 settings)
      cfg = cfg.split("\n")
      cfg.reject! { |line| line[/^#\s\w{3}\/\d{2}\/\d{4}.*$/] } # Remove date time and 'by RouterOS' comment (v6)
      cfg.reject! { |line| line[/^#\s\d{4}-\d{2}-\d{2}.*$/] }   # Remove date time and 'by RouterOS' comment (v7)
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
