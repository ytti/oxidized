class Dlink < Oxidized::Model
  using Refinements

  # D-LINK Switches

  prompt /[\w.@()\/:-]+[#>]\s?$/
  comment '# '

  cmd :secret do |cfg|
    cfg.gsub! /^(create snmp community) \S+/, '\\1 <removed>'
    cfg.gsub! /^(create snmp group) \S+/, '\\1 <removed>'
    cfg
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[2..-2].map { |line| line.delete("\r").rstrip }.join("\n") + "\n"
  end

  cmd 'show switch' do |cfg|
    cfg.gsub! /^System Uptime\s.+/, '' # Omit constantly changing uptime info
    cfg.gsub! /^System up time\s.+/, '' # Omit constantly changing uptime info
    cfg.gsub! /^System Time\s.+/, '' # Omit constantly changing uptime info
    cfg.gsub! /^RTC Time\s.+/, '' # Omit constantly changing uptime info
    comment cfg
  end

  cmd 'show vlan' do |cfg|
    comment cfg
  end

  cmd 'show config current'

  cfg :telnet do
    username /\r*([\w\s.@()\/:-]+)?([Uu]ser[Nn]ame|[Ll]ogin):/
    password /\r*[Pp]ass[Ww]ord:/
  end

  cfg :telnet, :ssh do
    post_login 'disable clipaging'
    post_login 'enable admin' if vars(:enable) == true
    pre_logout 'logout'
  end
end
