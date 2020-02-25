class GcomBNPS < Oxidized::Model
  # For switches from GCOM Technologies Co.,Ltd. running the "Broadband Network Platform Software"
  # Author: Frederik Kriewitz <frederik@kriewitz.eu>
  #
  # tested with:
  #  - S5330 (aka Fiberstore S3800)

  prompt /^\r?([\w.@()-]+?(\(1-\d+ chars\))?[#>:]\s?)$/ # also match SSH password promt (post_login commands are sent after the first prompt)
  comment '! '

  # alternative to handle the SSH login, but this breaks telnet
  #  expect /^Password\(1-\d+ chars\):/ do |data|
  #      send @node.auth[:password] + "\n"
  #      ''
  #  end

  # handle pager (can't be disabled?)
  expect /^\.\.\.\.press ENTER to next line, CTRL_C to quit, other key to next page\.\.\.\.$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg = cfg.gsub " \e[73D\e[K", '' # remove garbage remaining from the pager
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community)\s+[^\s]+\s+(.*)/, '\\1 <community hidden> \\2'
    cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cmd 'show interface sfp' do |cfg|
    out = []
    cfg.each_line do |line|
      next if line =~ /^  Temperature/
      next if line =~ /^  Voltage\(V\)/
      next if line =~ /^  Bias Current\(mA\)/
      next if line =~ /^  RX Power\(dBM\)/
      next if line =~ /^  TX Power\(dBM\)/

      out << line
    end

    comment out.join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    out = []
    cfg.each_line do |line|
      next if line =~ /^system run time        :/
      next if line =~ /^switch temperature     :/

      out << line
    end

    comment out.join
  end

  cfg :telnet do
    username /^Username\(1-\d+ chars\):/
    password /^Password\(1-\d+ chars\):/
  end

  cfg :ssh do
    # the switch blindy accepts the SSH connection without password validation and then spawns a telnet login prompt
    # first thing we've to send is the password
    post_login do
      send @node.auth[:password] + "\n"
    end
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
