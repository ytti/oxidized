class TrueNAS < Oxidized::Model
  using Refinements

  comment '# '

  cmd('uname -a') { |cfg| comment cfg }
  cmd('cat /etc/version') { |cfg| comment cfg }
  cmd('sqlite3 "file:///data/freenas-v1.db?mode=ro&immutable=1" .dump') do |cfg|
    cfg.lines.reject do |line|
      line.match(/^INSERT INTO storage_replication /) ||
        line.match(/^INSERT INTO system_alert /) || # ignore system alerts in db
        line.match(/^INSERT INTO sqlite_sequence VALUES\('system_alert',/) # ignore system alerts in db
    end.join
  end

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
