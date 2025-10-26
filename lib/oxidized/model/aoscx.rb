class Aoscx < Oxidized::Model
  using Refinements

  # previous command is repeated followed by "\eE", which sometimes ends up on last line
  # ssh switches prompt may start with \r, followed by the prompt itself, regex ([\w\s.-]+[#>] ), which ends the line
  # telnet switches may start with various vt100 control characters, regex (\e\[24;[0-9][hH]),
  # followed by the prompt, followed by at least 3 other vt100 characters
  prompt /(^\r|\e\[24;[0-9][hH])?([\w\s.-]+[#>] )($|(\e\[24;[0-9][0-9]?[hH]){3})/

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
    cfg = cfg.cut_both
    cfg = cfg.gsub /^\r/, ''
    # Additional filtering for elder switches sending vt100 control chars via telnet
    cfg.gsub! /\e\[\??\d+(;\d+)*[A-Za-z]/, ''
    # Additional filtering for power usage reporting which obviously changes over time
    cfg.gsub! /^(.*AC [0-9]{3}V\/?([0-9]{3}V)?) *([0-9]{1,3}) (.*)/, '\\1 <removed> \\4'
    cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(snmp-server host \S+) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(radius-server key).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(tacacs-server host \S+ key) \S+(.*)/, '\\1 <secret hidden> \\2'
    cfg.gsub! /^(tacacs-server key).*/, '\\1 <secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show environment' do |cfg|
    def with_section(cfg, section, &block)
      cfg.sub!(/(show environment #{section}.*?-{10,}\n)(.*?)(?=\nshow environment|\z)/m) do
        header = ::Regexp.last_match(1)
        content = ::Regexp.last_match(2)
        block.call(content) if block_given?
        header + content
      end
    end

    with_section(cfg, 'fan') do |content|
      content.gsub!(/^(.*)(slow|normal|medium|fast|max) (.*?)\d+ +$/, '\\1<speed> \\3<rpm>')
    end

    with_section(cfg, 'power-consumption') do |content|
      content.gsub!(/^(.*?) (?:\d+\.\d+ +)+\d+\.\d+$/, '\\1 <power hidden>')
    end

    with_section(cfg, 'power-allocation') do |content|
      content.gsub!(/^(.*) \d+ W$/, '\\1 <power>')
    end

    with_section(cfg, 'temperature') do |content|
      content.gsub!(/^(.*) \d+\.\d+ C (.*)$/, '\\1 <hidden>\\2')
    end
    comment cfg
  end

  cmd 'show module' do |cfg|
    comment cfg
  end

  cmd 'show interface transceiver' do |cfg|
    comment cfg
  end

  cmd 'show system | exclude "Up Time" | exclude "CPU" | exclude "Memory" | exclude "Pkts .x" | exclude "Lowest" | exclude "Missed"' do |cfg|
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
