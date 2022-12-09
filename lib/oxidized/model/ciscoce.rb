class CiscoCE < Oxidized::Model
  comment '! '

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp-server host \S+( vrf \S+)?( informs?)?( version (1|2c|3 (noauth|auth|priv)))?)\s+\S+((\s+\S*)*)\s*/, '\\1 <secret hidden> \\7'
    cfg.gsub! /^(username .+ (password|secret) \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(enable (password|secret)( level \d+)? \d) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+(?:password|secret)) (?:\d )?\S+/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*wpa-psk ascii \d) (\S+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(.*key 7) (\d.+)/, '\\1 <secret hidden>'
    cfg.gsub! /^(tacacs-server (.+ )?key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(crypto isakmp key) (\S+) (.*)/, '\\1 <secret hidden> \\3'
    cfg.gsub! /^(\s+ip ospf message-digest-key \d+ md5) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+ip ospf authentication-key) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+neighbor \S+ password) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+vrrp \d+ authentication text) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+standby \d+ authentication) .{1,8}$/, '\\1 <secret hidden>'
    cfg.gsub! /^(\s+standby \d+ authentication md5 key-string) .+?( timeout \d+)?$/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(\s+key-string) .+/, '\\1 <secret hidden>'
    cfg.gsub! /^((tacacs|radius) server [^\n]+\n(\s+[^\n]+\n)*\s+key) [^\n]+$/m, '\1 <secret hidden>'
    cfg.gsub! /^(\s+ppp (chap|pap) password \d) .+/, '\\1 <secret hidden>'
    cfg
  end

  cmd '/level/15/exec/-/show/version' do |cfg|
    cfg.gsub! /\A.+<DL>(.+)<\/DL>.+\z/m, '\1' # Strip data from within HTML response.
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

      comments << "Image:#{slave} Software: #{Regexp.last_match(1)}, #{Regexp.last_match(2)}" if line =~ /^(?:Cisco )?IOS .* Software,? \(([A-Za-z0-9_-]*)\), .*Version\s+(.*)$/

      comments << "ROM Bootstrap: #{Regexp.last_match(3)}" if line =~ /^ROM: (IOS \S+ )?(System )?Bootstrap.*(Version.*)$/

      comments << "BOOTFLASH: #{Regexp.last_match(1)}" if line =~ /^BOOTFLASH: .*(Version.*)$/

      comments << "Memory: nvram #{Regexp.last_match(1)}" if line =~ /^(\d+[kK]) bytes of (non-volatile|NVRAM)/

      comments << "Memory: flash #{Regexp.last_match(1)}" if line =~ /^(\d+[kK]) bytes of (flash memory|flash internal|processor board System flash|ATA CompactFlash)/i

      comments << "Memory: pcmcia #{Regexp.last_match(2)} #{Regexp.last_match(3)}#{Regexp.last_match(4)} #{Regexp.last_match(1)}" if line =~ /^(\d+[kK]) bytes of (Flash|ATA)?.*PCMCIA .*(slot|disk) ?(\d)/i

      if line =~ /(\S+(?:\sseries)?)\s+(?:\((\S+)\)\s+processor|\(revision[^)]+\)).*\s+with (\S+k) bytes/i
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
          cpuxtra = cfg.lines[i + 2].gsub(/implementation/, 'impl').gsub(/^/, ', ').chomp
        end
        comments << "CPU:#{slave} #{cpu}#{cpuxtra}#{slaveslot}"
      end

      comments << "Image: #{Regexp.last_match(1)}" if line =~ /^System image file is "([^"]*)"$/
    end
    comments << "\n"
    comment comments.join "\n"
  end

  cmd "/level/15/exec/-/show/vtp/status" do |cfg|
    cfg.gsub! /\A.+<DL>(.+)<\/DL>.+\z/m, '\1' # Strip data from within HTML response.
    cfg.gsub! /^$\n/, ''
    cfg.gsub! /Configuration last modified by.*\n/i, ''
    cfg.gsub! /^/, 'VTP: ' unless cfg.empty?
    comment "#{cfg}\n"
  end

  cmd "/level/15/exec/-/show/inventory/raw/CR" do |cfg|
    cfg.gsub! /\A.+<HR>(<DL>)*(.+)<\/DL>.+\z/m, '\2' # Strip data from within HTML response. There is a bug where the <DL> tag is ommitted in raw responses.
    cfg.gsub! /&#34;/, '"' # Unescape Quotations.
    cfg.gsub! /^PID: {3,20}, VID:.+\n/, '' # Strip empty PID: lines from inventory
    cfg.gsub! /\A/, "\n\n" # Add some space between VTP and inventory
    comment cfg
  end

  cmd "/level/15/exec/-/show/running-config/full" do |cfg|
    cfg.gsub! /\A.+<DL>(.+)<\/DL>.+\z/m, '\1' # Strip configuration file from within HTML response.
    cfg = cfg.each_line.to_a[3..-1]
    cfg = cfg.reject { |line| line.match /^ntp clock-period / }.join
    cfg.gsub! /^! .+\n/, '' # Remove comments added by Express GUI
    cfg.gsub! /^![A-F0-9]{4}/, '!' # Remove config checksum line
    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
    cfg.gsub! /^! (Last|No) configuration change (at|since).*\n/, ''
    cfg.gsub! /^! NVRAM config last updated.*\n/, ''
    cfg.gsub! /^ tunnel mpls traffic-eng bandwidth[^\n]*\n*(
                  (?: [^\n]*\n*)*
                  tunnel mpls traffic-eng auto-bw)/mx, '\1'
    cfg
  end

  cfg :http do
    @username = @node.auth[:username]
    @password = @node.auth[:password]
    @secure = false # Turning this on would be best, but these old switches only seem to support SSLv2, and that's no longer an option here
  end
end
