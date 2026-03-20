class Aoscx < Oxidized::Model
  using Refinements

  # HPE Aruba Networking - ArubaOS-CX models

  prompt /(^\r|\e\[24;[0-9][hH])?([\w\s.-]+[#>] )($|(\e\[24;[0-9][0-9]?[hH]){3})/

  comment '! '

  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  expect /\e\[\??\d+(;\d+)*[A-Za-z]/ do |data, re|
    data.gsub re, ''
  end

  expect /Press any key to continue(\e\[\??\d+(;\d+)*[A-Za-z])*$/ do
    send ' '
    ""
  end

  expect /Enter switch number/ do
    send "\n"
    ""
  end

  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^\r/, ''
    cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
    cfg.gsub! /^(.*AC [0-9]{3}V\/?([0-9]{3}V)?) *([0-9]{1,3}) (.*)/, '\\1 <removed> \\4'
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(user .* group .*(?: ciphertext)?) \S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server host \S+) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmpv3 user).*?(auth (?:md5|sha(?:\d{1,3})?) auth-pass ciphertext).*?(priv (?:des|aes(?:\d{1,3})?) priv-pass ciphertext).*/, '\\1 <user> \\2 <auth-pass> \\3 <priv-pass>'
    cfg.gsub! /^(radius-server host \S+ key(?: ciphertext)?) \S+ (.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(tacacs-server key).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show environment' do |cfg|
    cfg.gsub! /^(LC.*\s+)\d+\s+$/, '\\1<hidden>'
    cfg.gsub! /^(\d\/\d\/\d.*\s+)\d+\s+$/, '\\1<hidden>'
    cfg.gsub! /^(\d+\/?\S+\s+\S+\s+)\d+\.\d+\s+C\s+(.*)/, '\\1<hidden>   \\2'
    cfg.gsub! /^(LC.*\s+)\d+\.\d+\s+(C.*)$/, '\\1 <hidden> \\2'
    cfg.gsub! /^PSU(\S+\s+\S+\s+\s+\S+\s+)(slow|normal|medium|fast|max|N\/A)\s+(\S+\s+\S+\s+)\d+[[:blank:]]+/, '\\1<speed> \\3<rpm>'
    cfg.gsub! /^(\S+\s+\S+\s+\s+\S+\s+)(slow|normal|medium|fast|max)\s+(\S+\s+\S+\s+)\d+[[:blank:]]+/, '\\1<speed> \\3<rpm>'
    cfg.gsub! /^(\d+\s+.+\s+)(\s{2}\d{2}\.\d{2}|\s{1}\d{3}\.\d{2}|\d{4}\.\d{2})(\s+)(\s{2}\d{2}\.\d{2}|\s{1}\d{3}\.\d{2}|\d{4}\.\d{2})$/, '\\1<power>\\3<power>'
    cfg.gsub! /^(\d+\/?\d*\s+.+\s+)(\s{1,4}\d{1,3})\sW\s*$/, '\\1<power>'
    cfg.gsub! /^(Module|Chassis)\s(Total\sPower\sUsage)(\s+)\s(\s{4}\d{1}|\s{3}\d{2}|\s{2}\d{3}|\s{1}\d{4}|\d{5})\sW\s*$/, '\\1 <power>'
    cfg.gsub! /^(Chassis\sTotal\sPower\sUsage)(\s+)(\s{4}\d{1}|\s{3}\d{2}|\s{2}\d{3}|\s{1}\d{4}|\d{5})\sW\s*$/, '\\1\\2<power>'
    cfg.gsub! /^(Chassis\sTotal\sPower\s)(Allocated|Unallocated)(\s|\s\(total of all max wattages\))(\s+)(\s{4}\d{1}|\s{3}\d{2}|\s{2}\d{3}|\s{1}\d{4}|\d{5})\sW\s*$/, '\\1\\2\\3\\4<power>'
    cfg.gsub! /^([t|T]otal\s[p|P]ower\s[c|C]onsumption\s+)(\d+\.\d\d)$/, '\\1<power>'
    comment cfg
  end

  cmd 'show module' do |cfg|
    comment cfg
  end

  cmd 'show interface transceiver' do |cfg|
    comment cfg
  end

  cmd 'show system | exclude "Up Time" | exclude "CPU" | exclude "Memory" | exclude "Pkts .x" | exclude "Lowest" | exclude "Missed"' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :telnet do
    username /Username:/
    password /Password:/
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    post_login 'no page'
    pre_logout "exit"
  end

  cfg :ssh do
    pty_options(chars_wide: 1000)
  end
end
