class Procurve < Oxidized::Model
  using Refinements

  # The prompt is the device name followed by '#' or '>' and a
  # space, optionally preceded by a carriage return on ssh.
  prompt /(^\r)?([\w\s.-]+[#>] )$/

  comment '! '

  # These sequences are line breaks in the terminal stream: \e[1M...\e[1L is a
  # delete-line/insert-line redraw and \eE is NEL (next line). They must be
  # converted to newlines, not stripped, or the surrounding text concatenates.
  # This has to run before clean :escape_codes, which would otherwise remove the
  # \e[1M / \e[1L sequences (and does not match \eE at all).
  expect /(\e\[1M\e\[\??\d+(;\d+)*[A-Za-z]\e\[1L)|(\eE)/ do |data, re|
    data.gsub re, "\n"
  end

  # remove all other vt100 control sequences
  clean :escape_codes

  expect /Press any key to continue$/ do
    send "\n"
    ""
  end

  expect /Enter switch number/ do
    send "\n"
    ""
  end

  cmd :all do |cfg|
    cfg = cfg.cut_both
    cfg = cfg.gsub /^\r/, ''
    # Additional filtering for power usage reporting which obviously changes over time
    cfg.gsub! /^(.*AC [0-9]{3}V\/?([0-9]{3}V)?) *([0-9]{1,3}) (.*)/, '\\1 <removed> \\4'
    # Remove failed commands that are not supported on all models
    cfg.gsub! /^Invalid input: [A-Za-z-]+\n/, ''
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server host \S+)( community)? \S+(.*)/, '\\1\\2 <secret hidden>\\3'
    # local user password hashes; the quoted hash may wrap onto the next line
    cfg.gsub! /(sha1\s+)"\S+"/, '\\1"<secret hidden>"'
    cfg.gsub! /^(radius-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(tacacs-server key).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    clean_comment cfg
  end

  cmd 'show modules' do |cfg|
    clean_comment cfg
  end

  cmd 'show interfaces transceiver' do |cfg|
    clean_comment cfg
  end

  cmd 'show flash' do |cfg|
    clean_comment cfg
  end

  # not supported on all models
  cmd 'show system-information' do |cfg|
    cfg = cfg.cut_tail(7)
    clean_comment cfg
  end

  # not supported on all models
  cmd 'show system information' do |cfg|
    cfg = cfg.reject_lines ['CPU', 'Up Time', 'Total', 'Free', 'Lowest', 'Missed']
    clean_comment cfg
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
    pre_logout 'logout'
    pre_logout 'y'
    pre_logout 'n'
  end

  cfg :ssh do
    pty_options(chars_wide: 1000)
  end

  def clean_comment(lines)
    comment(lines).rstrip_lines
  end
end
