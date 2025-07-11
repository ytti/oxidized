class SonicOS < Oxidized::Model
  using Refinements

  # Applies to Sonicwall NSA series firewalls

  prompt /^\w+@[\w\-]+[>]\(?.+\)?\s?/
  comment '! '

  # Accept policiy message (see Issue #3339). Tested on 6.5 and 7.1
  expect /Accept The Policy Banner \(yes\)\?\r\nyes: $/ do |data, re|
    send "yes\n"
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /cli ftp password default \d,(\S+)/, 'cli ftp password default <secret hidden> \2'
    cfg.gsub! /secret \d,(\S+)/, 'secret <secret hidden> \2'
    cfg.gsub! /shared-secret \d,(\S+)/, 'shared-secret <secret hidden> \2'
    cfg.gsub! /password \d,(\S+)/, 'password <secret hidden> \2'
    cfg.gsub! /passphrase password \d,(\S+)/, 'passphrase password <secret hidden> \2'
    cfg.gsub! /bind-password \d,(\S+)/, 'bind-password <secret hidden> \2'
    cfg.gsub! /authentication sha1 \d,(\S+)/, 'authentication sha1 <secret hidden> \2'
    cfg.gsub! /encryption aes \d,(\S+)/, 'encryption aes <secret hidden> \2'
    cfg.gsub! /smtp-pass \d,(\S+)/, 'smtp-pass <secret hidden> \2'
    cfg.gsub! /pop-pass \d,(\S+)/, 'pop-pass <secret hidden> \2'
    cfg.gsub! /sslvpn password \d,(\S+)/, 'sslvpn password <secret hidden> \2'
    cfg.gsub! /administrator password \d,(\S+)/, 'administrator password <secret hidden> \2'
    cfg.gsub! /ftp password \d,(\S+)/, 'ftp password <secret hidden> \2'
    cfg.gsub! /shared-key \d,(\S+)/, 'shared-key <secret hidden> \2'
    cfg.gsub! /wpa passphrase \d,(\S+)/, 'wpa passphrase <secret hidden> \2'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg = comment clean cfg
    cfg << "\n"
  end

  cmd 'show current-config' do |cfg|
    cfg.gsub! /^: [^\n]*\n/, ''
    clean cfg
  end

  cfg :ssh do
    post_login 'no cli pager session'
    pre_logout 'exit'
  end

  def clean(cfg)
    out = []
    cfg.each_line do |line|
      next if line =~ /date \d{4}:\d{2}:\d{2}/
      next if line =~ /time \d{2}:\d{2}:\d{2}/
      next if line =~ /system-time "\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2}.\d+"/
      next if line =~ /system-uptime "(?:\s+up\s+\d+\s+|\d+ \w+(?:, \d+ \w+)*)"/
      next if line =~ /checksum \d+/

      line = line[1..-1] if line[0] == "\r"
      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
  end
end
