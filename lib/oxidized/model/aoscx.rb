class Aoscx < Oxidized::Model
  using Refinements

  # previous command is repeated followed by "\eE", which sometimes ends up on last line
  # ssh switches prompt may start with \r, followed by the prompt itself, regex ([\w\s.-]+[#>] ), which ends the line
  # telnet switchs may start with various vt100 control characters, regex (\e\[24;[0-9][hH]), follwed by the prompt, followed
  # by at least 3 other vt100 characters
  prompt /(^\r|\e\[24;[0-9][hH])?([\w\s.-]+[#>] )($|(\e\[24;[0-9][0-9]?[hH]){3})/

  comment '! '

  # replace next line control sequence with a new line
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # replace all used vt100 control sequences
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
    # Additional filtering for elder switches sending vt100 control chars via telnet
    cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
    # Additional filtering for power usage reporting which obviously changes over time
    cfg.gsub! /^(.*AC [0-9]{3}V\/?([0-9]{3}V)?) *([0-9]{1,3}) (.*)/, '\\1 <removed> \\4'
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server host \S+) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
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
    # match show environment No speed shown for switches CX83xx, e.g. "PSU-1/1/1      N/A      N/A            N/A     front-to-back  ok      7360"
    cfg.gsub! /^PSU(\S+\s+\S+\s+\s+\S+\s+)(slow|normal|medium|fast|max|N\/A)\s+(\S+\s+\S+\s+)\d+[[:blank:]]+/, '\\1<speed> \\3<rpm>'
    cfg.gsub! /^(\S+\s+\S+\s+\s+\S+\s+)(slow|normal|medium|fast|max)\s+(\S+\s+\S+\s+)\d+[[:blank:]]+/, '\\1<speed> \\3<rpm>'
    # match show environment power-consumption on VSF or standadlone, non-chassis and non-6400 switch, e.g. "2    6300M 48G 4SFP56 Swch                 156.00      155.94"
    cfg.gsub! /^(\d+\s+.+\s+)(\s{2}\d{2}\.\d{2}|\s{1}\d{3}\.\d{2}|\d{4}\.\d{2})(\s+)(\s{2}\d{2}\.\d{2}|\s{1}\d{3}\.\d{2}|\d{4}\.\d{2})$/, '\\1<power>\\3<power>'
    # match show environment power-consumption on 6400 or chassis switches, e.g. "1/4    line-card-module    R0X39A 6400 48p 1GbE CL4 PoE 4SFP56 Mod     54 W"
    cfg.gsub! /^(\d+\/?\d*\s+.+\s+)(\s{1,4}\d{1,3})\sW\s*$/, '\\1<power>'
    # match show environment power-consumption on 6400 or chassis switches, e.g. "Module Total Power Usage      13000 W", match up to a 5-digit number and keep table formatting.
    cfg.gsub! /^(Module|Chassis)\s(Total\sPower\sUsage)(\s+)\s(\s{4}\d{1}|\s{3}\d{2}|\s{2}\d{3}|\s{1}\d{4}|\d{5})\sW\s*$/, '\\1 <power>'
    # match show environment power-consumption on 6400 or chassis switches, e.g. "Chassis Total Power Usage     13000 W", match up to a 5-digit number and keep table formatting.
    cfg.gsub! /^(Chassis\sTotal\sPower\sUsage)(\s+)(\s{4}\d{1}|\s{3}\d{2}|\s{2}\d{3}|\s{1}\d{4}|\d{5})\sW\s*$/, '\\1\\2<power>'
    # match show environment power-consumption on 8400 or chassis switches, up to a 5-digit number, example matches:
    # e.g. "Chassis Total Power Allocated (total of all max wattages)               4130 W"
    # e.g. "Chassis Total Power Unallocated                                        15860 W"
    cfg.gsub! /^(Chassis\sTotal\sPower\s)(Allocated|Unallocated)(\s|\s\(total of all max wattages\))(\s+)(\s{4}\d{1}|\s{3}\d{2}|\s{2}\d{3}|\s{1}\d{4}|\d{5})\sW\s*$/, '\\1\\2\\3\\4<power>'
    # match Total Power Consumption:
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

  cmd 'show running-config'

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
