class C4CMTS < Oxidized::Model
  # Arris C4 CMTS

  prompt /^([\w.@:\/-]+[#>]\s?)$/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  cmd :secret do |cfg|
    cfg.gsub! /(.+)\s+encrypted-password\s+\w+\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(snmp-server community)\s+".*"\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(tacacs.*\s+key)\s+".*"\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /(cable authstring)\s+\w+\s+(.*)/, '\\1 <secret hidden> \\2'
    cfg
  end

  cmd 'show environment' do |cfg|
    cfg.gsub! /\s+[\-\d]+\s+C\s+[(\s\d]+\s+F\)/, '' # remove temperature readings
    comment cfg.cut_both
  end

  cmd 'show version' do |cfg|
    # remove uptime readings at char 55 and beyond
    cfg = cfg.each_line.map { |line| line.rstrip.slice(0..54) }.join("\n") + "\n"
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.cut_both
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    if vars :enable
      post_login do
        send "enable\n"
        send vars(:enable) + "\n"
      end
    end
    pre_logout 'exit'
  end
end
