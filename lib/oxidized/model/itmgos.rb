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

  cmd :secret do |cfg|
    # Prompted secrets are exported as the command, then the value and its confirmation:
    # "set tacacs+ secret", "admin ftp password", "set site chapsecret <site>" and so on.
    cfg.gsub!(/^((?:set|admin) (?:[^\n]*(?:password|phrase|secret|key)|site (?:dialoutpassword|chapsecret) [^\n]+)\n)[^\n]*\n[^\n]*\n/) do
      "#{Regexp.last_match(1)}<secret hidden>\n<secret hidden>\n"
    end
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
    cfg.reject_lines [
      /^The configuration will be output/,
      /^yes$/,
      /^One moment while the file is generated/
    ]
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
