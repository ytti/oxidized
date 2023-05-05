class TrueNAS < Oxidized::Model
  comment '# '

  cmd('uname -a') { |cfg| comment cfg }
  cmd('cat /etc/version') { |cfg| comment cfg }
  cmd('sqlite3 /data/freenas-v1.db .dump') do |cfg|
    cfg.lines.reject { |line|
      line.match(/^INSERT INTO storage_replication /) or
      line.match(/^INSERT INTO system_alert /)
    }.join()
  end

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
