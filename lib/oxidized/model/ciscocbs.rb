class CiscoCBS < Oxidized::Model
using Refinements

#Cisco Small Business CBS220 Switches
#https://www.cisco.com/c/en/us/support/switches/business-220-series-smart-switches/series.html
# Tested with 2.0.2.12 Firmware with Password Auth enabled

prompt /^[^\r\n]+[#>]/

comment '! '

cmd :all do |cfg|
lines = cfg.each_line.to_a[1..-2]
# Remove \r from beginning of response
lines[0].gsub!(/^\r.*?/, '') unless lines.empty?
lines.join
end

cmd :secret do |cfg|
cfg.gsub! /^(snmp-server community)./, '\1 '
cfg.gsub! /username (\S+) privilege (\d+) (\S+)./, ''
cfg.gsub! /^(username \S+ password encrypted) \S+(.)/, '\1 \2'
cfg.gsub! /^(enable password level \d+ encrypted) \S+/, '\1 '
cfg.gsub! /^(encrypted radius-server key)./, '\1 '
cfg.gsub! /^(encrypted radius-server host .+ key) \S+(.)/, '\1 \2'
cfg.gsub! /^(encrypted tacacs-server key)./, '\1 '
cfg.gsub! /^(encrypted tacacs-server host .+ key) \S+(.)/, '\1 \2'
cfg.gsub! /^(encrypted sntp authentication-key \d+ md5) ./, '\1 '
cfg
end

cmd 'show version' do |cfg|
cfg.gsub! /.Uptime for this control./, ''
cfg.gsub! /.System restarted./, ''
cfg.gsub! /uptime is\ .+/, ''
comment cfg
end

cmd 'show bootvar' do |cfg|
comment cfg
end

cmd 'show running-config' do |cfg|
cfg = cfg.each_line.to_a[0..-1].join
cfg.gsub! /^Current configuration : [^\n]\n/, ''
cfg.sub! /^(ntp clock-period)./, '! \1'
cfg.gsub! /^ tunnel mpls traffic-eng bandwidth[^\n]\n(
(?: [^\n]\n)*
tunnel mpls traffic-eng auto-bw)/mx, '\1'
cfg
end

cfg :telnet, :ssh do
username /User ?[nN]ame:/
password /^\r?Password:/

post_login 'terminal datadump' # Disable pager
post_login 'terminal width 0'
post_login 'terminal len 0'
pre_logout 'exit' # exit returns to previous priv level, no way to quit from exec(#)
pre_logout 'exit'
end
end
