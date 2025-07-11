class Unifiap < Oxidized::Model
  using Refinements

  # Ubiquiti Unifi AP circa 6.x
  # Should also work for unfi switches, and airOS, maybe they could be combined.
  # Since it relies on exec channels, because the interactive session wouldn't
  # capture all of the system.cfg output, you can't use telnet with this model.

  # Sometimes there's a handy info command that summarizes some device attributes,
  # but it doesn't seem to be available in exec mode. So we try to build up a similar
  # list by extracting tidbits from various places. AirOS doesn't have some of these
  # files, so we  # may have to fall back on other commands, or locations.

  # First get the board model
  cmd 'head -4 /etc/board.info' do |cfg|
    @model = Regexp.last_match(1) if cfg =~ /board\.name=(\S+)/i
    ""
  end

  # and version
  cmd 'cat /etc/version' do |cfg|
    @version = Regexp.last_match(1) if cfg =~ /(\S+)$/i
    ""
  end

  # Now the Mac address
  cmd 'ifconfig eth0' do |cfg|
    @mac = Regexp.last_match(1) if cfg =~ /eth0\s+Link encap:Ethernet\s+HWaddr\s+(\w+:\w+:\w+:\w+:\w+:\w+)/i
    ""
  end

  # Next see if we can get our IP and host name out of /etc/hosts
  cmd 'cat /etc/hosts' do |cfg|
    cfg = cfg.split("\n").reject do |line|
      line[/^\s*(127|0000:0000:0000:0000:0000:0000:0000:0001|0:0:0:0:0:0:0:1|::1)/]
    end
    cfg.select do |line|
      if (match = line.match(/(\d+\.\d+\.\d+\.\d+)\s+(\S+)/))
        @ip, @hostname = match.captures
      end
    end
    ""
  end

  # We check here to see if we succeeded with /etc/hosts. If not, then we try again with ifconfig, and /tmp/system.cfg
  cmd 'echo' do
    unless @ip
      cmd 'ifconfig br0' do |cfg|
        @ip = Regexp.last_match(1) if cfg =~ /inet addr:\s*(\d+\.\d+\.\d+\.\d+)/i
      end

      unless @ip
        cmd 'ifconfig eth0' do |cfg|
          @ip = Regexp.last_match(1) if cfg =~ /inet addr:\s*(\d+\.\d+\.\d+\.\d+)/i
        end
      end
    end

    unless @hostname
      cmd 'cat /tmp/system.cfg' do |cfg|
        @hostname = Regexp.last_match(1) if cfg =~ /resolv.host.1.name=(\S+)/i
      end
    end
    ""
  end

  # Check if ntpclient is running
  cmd 'ps wwww' do |cfg|
    @ntpserver = Regexp.last_match(1) if cfg =~ /bin\/ntpclient.+-h\s*(\S+)/i
    ""
  end

  # If it's a Unifi device it may have NTP health indication
  # If there are other places that Ubiquiti puts these status files, add them here.
  cmd '[ -e /tmp/run/ntp.ready ] || [ -e /var/run/ntp.ready ] && echo "File(s) exist(s)" || echo "No such file"' do |cfg|
    if cfg =~ /No such file/i
      if @ntpserver
        # Ok, now lets try getting the skew from the output of ntpclient
        cmd "ntpclient -d -n -c 2 -i0 -h #{@ntpserver}" do |ntp_out|
          @skew = ntpskew(ntp_out)
        end
        @sync = !@skew.nil? && @skew.to_f.abs < 1e6 ? "Synchronized" : "FAIL"
      end
    else
      @ntpserver = true
      @sync = "Synchronized"
    end
    ""
  end

  # Now we can display it all as a banner
  cmd 'echo' do
    out = []
    out << "*************************"
    out << "Model:       #{@model}"
    out << "Version:     #{@version}"
    out << "MAC Address: #{@mac}"
    out << "IP Address:  #{@ip}"
    out << "Hostname:    #{@hostname}"
    out << "NTP:         #{@sync}" if @ntpserver
    out << "*************************"
    comment out.join("\n") + "\n"
  end

  # Followed by the board info
  cmd 'cat /etc/board.info' do |cfg|
    cfg = "#\n# Board Info:\n#\n" + cfg
    comment cfg
  end

  # Lastly the system config
  cmd 'cat /tmp/system.cfg' do |cfg|
    cfg = "#\n# System Config:\n#\n" + cfg
    cfg + "\n"
  end

  cmd :secret do |cfg|
    cfg.gsub! /^((?:users|snmp\.(?:user|community))\.\d+\.password)=.+/, "# \\1=<hidden>"
    cfg
  end

  cfg :ssh do
    exec true # Don't run shell, run each command in exec channel
  end

  # NTPskew: Return the skew in micro seconds from the ntpclient output
  def ntpskew(cfg)
    index = skew = nil

    cfg.each_line do |line|
      # Look for the header just before the stats line, and find which number is skew
      if line.match(/^\s*[a-z]+\s+[a-z]+\s+[a-z]+\s+[a-z]+/i)
        words = line.split
        index = words.map(&:downcase).index("skew")
      end
      # Now look for the single stats line and grab the skew
      if !index.nil? && line.match(/^\s*[\d.]+\s+[\d.]+\s+[\d.]+\s+[\d.]+/)
        numbers = line.split
        skew = numbers[index]
      end
    end
    skew
  end
end
