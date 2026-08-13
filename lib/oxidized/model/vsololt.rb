class VSOLOLT < Oxidized::Model
  using Refinements

  # Tested with VSOL V1600G0-B GPON OLT, software V1.4.13R

  # The device runs its CLI in three modes, all matched here:
  #   user mode:   RT_01|192.0.2.4-Site_OLT>
  #   enable mode: RT_01|192.0.2.4-Site_OLT#
  #   config mode: RT_01|192.0.2.4-Site_OLT(config)#
  # The hostname can contain '|', '.', '-' and the prompt appends '(config)'.
  prompt /^([\w.@|()\/-]+[#>]\s?)$/
  comment '! '

  # The OLT continuously prints log events into the SSH session and there is no
  # known way to disable them. They all start with a "YYYY/MM/DD HH:MM:SS"
  # timestamp, e.g.:
  #   2026/05/25 17:08:24   ONU Port Los   PON 0/3 ONU 50 sn ... LAN1 LINK DOWN
  # Strip them so they don't pollute the collected configuration.
  cmd :all do |cfg|
    cfg.gsub! /^\d{4}\/\d{2}\/\d{2}\s+\d{2}:\d{2}:\d{2}\s+.*$\n?/, ''
    # Pager redraw orphans: after we answer the " --More-- " pager with a space,
    # the device erases its 10-character prompt by emitting 10x BACKSPACE +
    # 10x SPACE + 10x BACKSPACE before redrawing the next line in its place.
    # Left untouched, this glues the last line of a page to the first line of
    # the next one. (See tnsr.rb for an analogous case with a different byte
    # count: there the prompt is "--More--" cleared with 8x \x08\x20\x08.)
    cfg.gsub! /\x08{10}\x20{10}\x08{10}/, ''
    # NUL byte trailing the " --More-- " marker, in case expect didn't catch it.
    cfg.gsub! "\x00", ''
    cfg.cut_both
  end

  # Pager handling. The device paginates with a " --More-- \x00" line (note the
  # leading/trailing space and the trailing NUL byte). Advance with a space.
  # Only consume the spaces on the pager's own line (and the NUL) here, NOT the
  # preceding newline, so the previous config line stays on its own line. The
  # backspace/space redraw orphans are cleaned in cmd :all above.
  expect /\x20*--More--\x20*\x00?/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :secret do |cfg|
    # SNMP community string. It appears both as "snmp-server community <X> ro|rw"
    # and inside "snmp-server host ... version 2c community <X>"; anchor to
    # "snmp-server" so we don't touch the word "community" elsewhere.
    cfg.gsub! /^(snmp-server .*community) \S+/, '\\1 <secret hidden>'
    # OLT admin accounts:
    #   user add admin login-password X
    #   user role admin ADMIN enable-password X
    cfg.gsub! /(login-password)\s+\S+/, '\\1 <secret hidden>'
    cfg.gsub! /(enable-password)\s+\S+/, '\\1 <secret hidden>'
    # client account passwords on ONUs, e.g.
    #   ... username admin_control enable admin PW1 user_control enable user PW2
    # PW1 follows "enable <role>", PW2 follows "user_control enable <role>".
    cfg.gsub! /(username \S+ enable \S+)\s+\S+/, '\\1 <secret hidden>'
    cfg.gsub! /(user_control enable \S+)\s+\S+/, '\\1 <secret hidden>'
    # client (ONU) Wi-Fi PSK: ... shared_key PW rekey_interval ...
    cfg.gsub! /(shared_key)\s+\S+/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show pon transceiver-info all' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    # Filtering the injected log messages (see cmd :all) leaves behind the
    # blank line(s) the device printed around each async message. The
    # running-config uses '!' as section separators, not blank lines, so
    # collapse any run of empty lines to drop those artifacts.
    cfg.gsub! /(?:\r?\n[ \t]*){2,}/, "\n"
    cfg
  end

  cfg :ssh do
    # The show commands are only available after entering enable + config mode.
    # The enable password equals the SSH login password (vars(:enable) overrides).
    post_login do
      send "enable\n"
      expect /[pP]assword:\s*$/
      send (vars(:enable) || @node.auth[:password]).to_s + "\n"
      expect /[#>]\s*$/
    end
    post_login 'configure terminal'
    pre_logout 'end'
    pre_logout 'exit'
  end
end
