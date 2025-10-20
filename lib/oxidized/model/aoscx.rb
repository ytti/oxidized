class Aoscx < Oxidized::Model
  # previous command is repeated followed by "\eE", which sometimes ends up on last line
  # ssh switches prompt may start with \r, followed by the prompt itself, regex ([\w\s.-]+[#> ] ), which ends the line
  # telnet switches may start with various vt100 control characters, regex (\e\[24;[0-9][hH]), followed by the prompt, followed
  # by at least 3 other vt100 characters
  prompt /(^\r|\e\[24;[0-9][hH])?([\w\s.-]+[#> ] )($|(\e\[24;[0-9][0-9]?[hH]){3})/

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
    # Removed: cfg = cfg.cut_both
    cfg = cfg.gsub(/^\r/, '')
    # Additional filtering for elder switches sending vt100 control chars via telnet
    cfg.gsub!(/\e\[\??\d+(;\d+)*[A-Za-z]/, '')
    # Additional filtering for power usage reporting which obviously changes over time
    cfg.gsub!(/^(.*AC [0-9]{3}V\/?([0-9]{3}V)?) *([0-9]{1,3}) (.*)/, '\\1 <removed> \\4')
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub!(/^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2')
    cfg.gsub!(/^(snmp-server host \S+) \S+(.*)/, '\\1 <secret hidden> \\2')
    cfg.gsub!(/^(radius-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2')
    cfg.gsub!(/^(radius-server key).*/, '\\1 <configuration removed>')
    cfg.gsub!(/^(tacacs-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2')
    cfg.gsub!(/^(tacacs-server key).*/, '\\1 <secret hidden>')
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show environment' do |cfg|
    # === Mask volatile power sections with stable placeholders ===

    # Devices that echo the subcommand header:
    cfg.gsub!(
        /^\s*show environment power-supply input-voltage.*?(?=^\s*show\s|\Z)/mi,
        "show environment power-supply input-voltage\n<hidden>\n"
    )
    cfg.gsub!(
        /^\s*show environment power-consumption.*?(?=^\s*show\s|\Z)/mi,
        "show environment power-consumption\n<hidden>\n"
    )

    # Devices that don't echo the subcommand header; use the “Averaging Period” anchors:
    cfg.gsub!(
        /^\s*Input Voltage Averaging Period\s*:.*?(?=^\s*\S|\Z)/mi,
        "show environment power-supply input-voltage\n<hidden>\n"
    )
    cfg.gsub!(
        /^\s*Power Consumption Averaging Period\s*:.*?(?=^\s*\S|\Z)/mi,
        "show environment power-consumption\n<hidden>\n"
    )

    # === Mask temperatures within 'show environment temperature' ===
    # Replace numeric temps inside that subsection only (e.g., "40.50 C" -> "<hidden>")
    cfg.gsub!(/(^\s*show environment temperature.*?)(?=^\s*show\s|\Z)/mi) do |section|
        section.gsub(/(\s)-?\d+(?:\.\d+)?\s*[CF]\b/i, '\1<hidden>')
    end

    # === Mask fan speed state and RPMs within fan-related subsections ===
    # Covers: 'show environment fan', 'fans', 'fan-tray'
    cfg.gsub!(/(^\s*show environment (?:fan(?:s|-tray)?).*?)(?=^\s*show\s|\Z)/mi) do |section|
        s = section.dup

        # 1) Mask common speed/state words (keeps airflow 'front-to-back' as-is)
        s.gsub!(/\b(normal|high|low|slow|fast|medium|auto)\b/i, '<speed>')

        # 2) Mask explicit "1234 rpm" forms
        s.gsub!(/\b\d{3,6}\s*rpm\b/i, '<rpm>')

        # 3) Mask trailing numeric RPM at end-of-line table column (e.g., "... ok      9600")
        s.gsub!(/(^.*?\s)(\d{3,6})\s*$/i, '\1<rpm>')

        s
    end

    # Tidy up extra blank lines
    cfg.gsub!(/\n{3,}/, "\n\n")

    comment cfg
  end

  cmd 'show module' do |cfg|
    comment cfg
  end

  cmd 'show interface transceiver' do |cfg|
    comment cfg
  end

  cmd 'show system | exclude "Up Time" | exclude "CPU" | exclude "Memory"' do |cfg|
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