class SonicOS < Oxidized::Model

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
    comment cfg.each_line.reject { |line| line.match /system-time \"\d{2}\/\d{2}\/\d{4} \d{2}\:\d{2}:\d{2}.\d+\"/ or line.match /system-uptime "(\s+up\s+\d+\s+)|(.*Days.*)"/ }.join
    comment cfg
  end

  cmd 'show current-config' do |cfg|
    cfg.each_line.reject { |line| line.match /checksum \d+/ }.join
    cfg = cfg.each_line.to_a[3..-1].join
    cfg.gsub! /^: [^\n]*\n/, ''
    cfg
  end

  cfg :ssh do
    post_login 'no cli pager session'
    pre_logout 'exit'
  end

end
