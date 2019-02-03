class Planet < Oxidized::Model
  prompt /^\r?([\w.@()-]+[#>]\s?)$/
  comment  '! '

  # example how to handle pager
  # expect /^\s--More--\s+.*$/ do |data, re|
  # send ' '
  # data.sub re, ''
  # end

  # non-preferred way to handle additional PW prompt
  # expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  # end

  cmd :all do |cfg|
    # cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    # cfg.gsub! /\cH+/, ''              # example how to handle pager
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^username \S+ password \d \S+/, '<secret hidden>'
    cfg.gsub! /^enable password \d \S+/, '<secret hidden>'
    cfg.gsub! /wpa-psk ascii \d \S+/, '<secret hidden>'
    cfg.gsub! /^tacacs-server key \d \S+/, '<secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg.gsub! "\n\r", "\n"
    @planetgs = true if cfg =~ /^System Name\w*:\w*GS-.*$/
    @planetsgs = true if cfg =~ /SGS-(.*) Device, Compiled on .*$/

    cfg = cfg.each_line.to_a[0...-2]

    # Strip system (up)time and temperature
    cfg = cfg.reject { |line| line.match /System Time\s*:.*/ }
    cfg = cfg.reject { |line| line.match /System Uptime\s*:.*/ }
    cfg = cfg.reject { |line| line.match /Temperature\s*:.*/ }

    comment cfg.join
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! "\n\r", "\n"
    cfg = cfg.each_line.to_a

    cfg = cfg.reject { |line| line.match "Building configuration..." }

    if @planetsgs
      cfg << cmd('show transceiver detail | include transceiver detail information|found|Type|length|Nominal|wavelength|Base information') do |cfg_optic|
        comment cfg_optic
      end
    end

    cfg.join
  end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    pre_logout 'exit'
  end
end
