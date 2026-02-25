class Aoscx < Oxidized::Model
  using Refinements
  # HPE Aruba Networking - ArubaOS-CX models

  prompt /^[\w\s.-]+[#>] $/
  clean :escape_codes

  comment '! '

  expect /Press any key to continue$/ do
    send ' '
    ""
  end

  expect /Enter switch number/ do
    send "\n"
    ""
  end

  cmd :all do |cfg|
    cfg.cut_both
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
      content.gsub!(/^(.*)(slow|normal|medium|fast|max|N\/A) (.*?)\d+ +$/, '\\1<speed> \\3<rpm>')
    end

    with_section(cfg, 'power-consumption') do |content|
      content.gsub!(/^(.*?) (?:\d+\.\d+ +)+\d+\.\d+$/, '\\1 <power hidden>')
    end

    with_section(cfg, 'power-allocation') do |content|
      content.gsub!(/^(.*) \d+ W$/, '\\1 <power>')
    end

    with_section(cfg, 'temperature') do |content|
      content.gsub!(/^(.*) -?\d+\.\d+ C (.*)$/, '\\1 <hidden>\\2')
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
