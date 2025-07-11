class IOS < Oxidized::Model
  using Refinements

  prompt /^([\w.@()-]+[#>]\s?)$/
  comment  '! '

  # example how to handle pager
  # expect /^\s--More--\s+.*$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  # end

  # non-preferred way to handle additional PW prompt
  # expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  # end

  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    # cfg.gsub! /\cH+/, ''              # example how to handle pager
    # get rid of errors for commands that don't work on some devices
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp-server host \S+( vrf \S+)?( informs?)?( version (1|2c))?) +\S+( .*)?$*/, '\\1 <secret hidden>\\6'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( +(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*wpa-psk ascii \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*key 7) (\d.+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(crypto isakmp key) (\S+) (.*)/, '\\1 <secret hidden> \\3'
    cfg.gsub! /^( +ip ospf message-digest-key \d+ md5) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( +ip ospf authentication-key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( +neighbor \S+ password) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( +vrrp \d+ authentication text) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( +standby \d+ authentication) .{1,8}$/, '\\1 <secret hidden>'
    cfg.gsub! /^( +standby \d+ authentication md5 key-string) .+?( timeout \d+)?$/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^( +key-string) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^((tacacs|radius) server [^\n]+\n( +[^\n]+\n)* +key) [^\n]+$/m, '\1 <secret hidden>'
    cfg.gsub! /^( +ppp (chap|pap) password \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^( +security wpa psk set-key (?:ascii|hex) \d) (.*)$/, '\\1 <secret hidden>'
    cfg.gsub! /^( +dot1x username \S+ password \d) (.*)$/, '\\1 <secret hidden>'
    cfg.gsub! /^( +mgmtuser username \S+ password \d) (.*) (secret \d) (.*)$/, '\\1 <secret hidden> \\3 <secret hidden>'
    cfg.gsub! /^( +client \S+ server-key \d) (.*)$/, '\\1 <secret hidden>'
    cfg.gsub! /^( +domain-password) \S+ ?(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^( +pre-shared-key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(.*server-key(?: \d)?) \S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comments = []
    comments << cfg.lines.first
    lines = cfg.lines
    lines.each_with_index do |line, i|
      slave = ''
      slaveslot = ''

      if line =~ /^Slave in slot (\d+) is running/
        slave = " Slave:"
        slaveslot = ", slot #{Regexp.last_match(1)}"
      end

      comments << "Image:#{slave} Compiled: #{Regexp.last_match(1)}" if line =~ /^Compiled (.*)$/

      if line =~ /^(?:Cisco )?IOS .* Software,? \(([A-Za-z0-9_-]*)\), .*Version\s+(.*)$/
        comments << "Image:#{slave} Software: #{Regexp.last_match(1)}, #{Regexp.last_match(2)}"
      end

      if line =~ /^ROM: (IOS \S+ )?(System )?Bootstrap.*(Version.*)$/
        comments << "ROM Bootstrap: #{Regexp.last_match(3)}"
      end

      comments << "BOOTFLASH: #{Regexp.last_match(1)}" if line =~ /^BOOTFLASH: .*(Version.*)$/

      comments << "Memory: nvram #{Regexp.last_match(1)}" if line =~ /^(\d+[kK]) bytes of (non-volatile|NVRAM)/

      if line =~ /^(\d+[kK]) bytes of (flash memory|flash internal|processor board System flash|ATA CompactFlash)/i
        comments << "Memory: flash #{Regexp.last_match(1)}"
      end

      if line =~ /^(\d+[kK]) bytes of (Flash|ATA)?.*PCMCIA .*(slot|disk) ?(\d)/i
        comments << "Memory: pcmcia #{Regexp.last_match(2)} #{Regexp.last_match(3)}#{Regexp.last_match(4)} #{Regexp.last_match(1)}"
      end

      if line =~ /(\S+(?:\sseries)?)\s+(?:\(([\S ]+)\)\s+processor|\(revision[^)]+\)).*\s+with (\S+k) bytes/i
        sproc = Regexp.last_match(1)
        cpu = Regexp.last_match(2)
        mem = Regexp.last_match(3)
        cpuxtra = ''
        comments << "Chassis type:#{slave} #{sproc}"
        comments << "Memory:#{slave} main #{mem}"
        # check the next two lines for more CPU info
        comments << "Processor ID: #{Regexp.last_match(1)}" if cfg.lines[i + 1] =~ /processor board id (\S+)/i
        if cfg.lines[i + 2] =~ /(cpu at |processor: |#{cpu} processor,)/i
          # change implementation to impl and prepend comma
          cpuxtra = cfg.lines[i + 2].gsub("implementation", 'impl').gsub(/^/, ', ').chomp
        end
        comments << "CPU:#{slave} #{cpu}#{cpuxtra}#{slaveslot}"
      end

      comments << "Image: #{Regexp.last_match(1)}" if line =~ /^System image file is "([^"]*)"$/
    end
    comments << "\n"
    comment comments.join "\n"
  end

  cmd 'show vtp status' do |cfg|
    cfg.gsub! /^$\n/, ''
    cfg.gsub! /Configuration last modified by.*\n/, ''
    cfg.gsub! /^/, 'VTP: ' unless cfg.empty?
    comment "#{cfg}\n"
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  post do
    cmd_line = 'show running-config'
    cmd_line += ' view full' if vars(:ios_rbac)
    cmd cmd_line do |cfg|
      cfg = cfg.each_line.to_a[3..-1]
      cfg = cfg.reject { |line| line.match /^ntp clock-period / }.join
      cfg = cfg.each_line.reject do |line|
        line.match /^! (Last|No) configuration change (at|since).*/ unless line =~ /\d+\sby\s\S+$/
      end.join
      cfg.gsub! /^Current configuration : [^\n]*\n/, ''
      cfg.gsub! /^ tunnel mpls traffic-eng bandwidth[^\n]*\n*(
                    (?: [^\n]*\n*)*
                    tunnel mpls traffic-eng auto-bw)/mx, '\1'
      # get rid of values of custom SNMP OID's
      cfg.gsub! /^(\s+expression) \d+$/, '\\1 <value removed>'
      cfg
    end
  end

  cfg :telnet do
    username /^Username:/i
    password /^Password:/i
  end

  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    post_login do
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/
        cmd vars(:enable)
      end
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout 'exit'
  end
end
