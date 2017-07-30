class SonicOS < Oxidized::Model
# Applies to Sonicwall NSA series firewalls

  prompt /^\w+@\w+[>]\(?.+\)?\s?/
  comment  '! '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /cli ftp password default \d\,(\S+)/, 'cli ftp password default <secret hidden> \2'
    cfg.gsub! /secret \d\,(\S+)/, 'secret <secret hidden> \2'
    cfg.gsub! /shared-secret \d\,(\S+)/, 'shared-secret <secret hidden> \2'
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

  cfg :telnet, :ssh do
    post_login 'no cli pager session'
    pre_logout 'exit'
  end

  def clean cfg
    out = []
    cfg.each_line do |line|
      next if line.match /system-time \"\d{2}\/\d{2}\/\d{4} \d{2}\:\d{2}:\d{2}.\d+\"/
      next if line.match /system-uptime "(\s+up\s+\d+\s+)|(.*Days.*)"/
      next if line.match /checksum \d+/
      line = line[1..-1] if line[0] == "\r"
      out << line.strip
    end
    out = out.join "\n"
    out << "\n"
  end


end
