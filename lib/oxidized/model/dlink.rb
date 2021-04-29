class Dlink < Oxidized::Model
  # D-LINK Switches
  # Add support dgs 1100 series (tested only with dgs-1100-10/me)

  prompt /^(\r*[\w\s.@()\/:-]+[#>]\s?)$/
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
    pre_logout 'logout'
  end
end
