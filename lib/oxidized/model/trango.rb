class Trango < Oxidized::Model
  # take a Trangolink sysinfo output and turn it into a configuration file
  
  prompt /^#>\s?/
  comment  '# '

  cmd 'sysinfo' do |cfg|
    out = []
    comments = []
    cfg.each_line do |line|
      if line.match /\[Opmode\] (off|on) \[Default Opmode\] (off|on)/
        out << "opmode " + Regexp.last_match[1]
        out << "defaultopmode " + Regexp.last_match[2]
      end
      if line.match /\[Tx Power\] ([\-\d]+) dBm/
        out << "power " + Regexp.last_match[1]
      end
      if line.match /\[Active Channel\] (\d+) (v|h)/
        out << "freq " + Regexp.last_match[1] + ' ' + Regexp.last_match[2]
      end
      if line.match /\[Peer ID\] ([A-F0-9]+)/
        out << "peerid " + Regexp.last_match[1]
      end
      if line.match /\[Unit Type\] (\S+)/
        out << "utype " + Regexp.last_match[1]
      end
      if line.match /\[(Hardware Version|Firmware Version|Model|S\/N)\] (\S+)/
        comments << '# ' + Regexp.last_match[1] + ': ' + Regexp.last_match[2]
      end
      if line.match /\[Remarks\] (\S+)/
        out << "remarks " + Regexp.last_match[1]
      end
      if line.match /\[RSSI LED\] (on|off)/
        out << "rssiled " + Regexp.last_match[1]
      end
      if line.match /\[Speed\] (\d+) Mbps/
        speed = Regexp.last_match[1]
      end
      if line.match /\[Tx MIR\] (\d+) Kbps/
        out << "mir ".concat(Regexp.last_match[1])
      end
      if line.match /\[Auto Rate Shift\] (on|off)/
        out << "autorateshift ".concat(Regexp.last_match[1])
        if Regexp.last_match[1].eql? 'off'
          out << "speed $speed"
        end
      end
      if line.match /\[IP\] (\S+) \[Subnet Mask\] (\S+) \[Gateway\] (\S+)/
        out << "ipconfig " + Regexp.last_match[1] + ' ' +
                              Regexp.last_match[2] + ' ' +
                              Regexp.last_match[3]
      end
    end 
    comments.push(*out).join "\n"
  end 

  cfg :telnet do
    password /Password:/
    pre_logout 'exit'
  end
 
end
