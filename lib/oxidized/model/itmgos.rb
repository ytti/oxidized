class ITMGOS < Oxidized::Model
  using Refinements

  # Lantronix IT Management Gateway OS: SLC 8000, SLC 9000, EMG 8500/7500 and SLB.
  # The configuration is the device's own CLI export, which it can restore with
  # "admin config batch".

  prompt /^(\[[\w.-]{1,64}\]>\s?)$/
  comment '# '

  # The export asks before printing secrets in cleartext; :secret below removes them.
  expect /Do you want to continue\? \[no\] $/ do |data, re|
    send "yes\n"
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg = cfg.gsub(/\r\n?/, "\n")
    cfg.cut_both
  end

  # Prompted secrets are exported as the command, then the value and its confirmation on
  # the next two lines: "set tacacs+ secret", "admin ftp password", "set site chapsecret
  # <site>" and so on. Those two lines are hidden whatever they contain.
  PROMPTED_SECRET = /^(?:set|admin) (?:.*(?:password|phrase|secret|key)|site (?:dialoutpassword|chapsecret) \S.*?)\s*$/

  # Lines the export prints before the first command.
  EXPORT_PREAMBLE = /^(?:\s*|The configuration will be output.*|yes|One moment while the file is generated.*)$/

  cmd :secret do |cfg|
    lines = cfg.lines
    i = 0
    while i < lines.length
      if lines[i].match?(PROMPTED_SECRET)
        lines[i + 1, 2] = lines[i + 1, 2].map { |line| line.end_with?("\n") ? "<secret hidden>\n" : '<secret hidden>' }
        i += 3
      else
        i += 1
      end
    end
    cfg = lines.join
    # All three communities can share one line, quoted: rocommunity 'public' rwcommunity ...
    cfg.gsub!(/\b((?:ro|rw|trap)community) (?:'[^'\n]*'|"[^"\n]*"|\S+)/, "\\1 '<secret hidden>'")
    # Event actions that send traps carry their own community.
    cfg.gsub!(/(\saction snmptrap\b[^\n]*?\scommunity) (?:'[^'\n]*'|"[^"\n]*"|\S+)/, '\1 <secret hidden>')
    cfg.gsub!(/^(set localusers password \S+ enc) \S+/, '\1 <secret hidden>')
    cfg
  end

  cmd 'admin version' do |cfg|
    cfg = cfg.reject_lines [
      /^Uptime:/,
      /^Last (Boot|Restart Reason|Power Outage)/
    ]
    comment cfg + "\n"
  end

  cmd 'admin config commands copypaste' do |cfg|
    # Only the preamble is dropped, so a secret whose value is "yes" stays in the export.
    lines = cfg.lines
    lines.shift while lines.any? && lines.first.match?(EXPORT_PREAMBLE)
    lines.join
  end

  cfg :ssh, :telnet do
    post_login 'set cli terminallines disable'
    pre_logout 'logout'
  end

  cfg :telnet do
    username /^login:\s*$/i
    password /^password:\s*$/i
  end
end
