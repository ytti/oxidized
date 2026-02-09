class DlinkDgs125052x < Oxidized::Model
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

  cmd 'show vlan' do |cfg|
    comment cfg
  end

  cmd 'show running-config'

  cfg :telnet do
    username /\r*([\w\s.@()\/:-]+)?([Uu]ser[Nn]ame|[Ll]ogin):/
    password /\r*[Pp]ass[Ww]ord:/
  end

  cfg :telnet, :ssh do
    post_login 'disable clipaging'
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'logout'
  end
end
