class FS < Oxidized::Model
  # For switches from FS.com
  # Author: David Croft <davidc.net>
  #
  # tested with:
  #  - Fiberstore S3900-24F4S
  #  - Fiberstore S5800-8TF12S

  prompt /^\r?([\w.@()-]+?(\(1-16 chars\))?[#>:]\s?)$/
  comment '! '

  # handle pager
  expect /^--- \[Space\] Next page, \[Enter\] Next line, \[A\] All, Others to exit ---$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg = cfg.gsub "\08", '' # remove backspaces remaining from the pager
    cfg.cut_both
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community)\s+[^\s]+\s+(.*)/, '\\1 <community hidden> \\2'
    cfg
  end

  cmd 'dir' do |cfg|
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /^Building running configuration. Please wait...$/, ''
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show system' do |cfg|
    out = []
    cfg.each_line do |line|
      next if line =~ /FS-SW Up Time/
      next if line =~ /Temperature [0-9]:/

      out << line
    end

    comment out.join
  end

  cfg :telnet do
    username /^Username\(1-32 chars\):/
    password /^Password\(1-16 chars\):/
  end

  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end
end
