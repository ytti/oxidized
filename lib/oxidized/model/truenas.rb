class TrueNAS < Oxidized::Model
  using Refinements

  comment '# '

  cmd('uname -a') { |cfg| comment cfg }
  cmd('cat /etc/version') { |cfg| comment cfg }

  # for TrueNAS SCALE machines, make sure the user you use to connect can run
  # this command, or if needed, with passwordless sudo. Try putting this in
  # /etc/sudoers
  #    oxidized ALL=(ALL) NOPASSWD: /usr/bin/sqlite3 file\:///data/freenas-v1.db?mode\=ro&immutable\=1 .dump

  cmd("sqlite3 'file:///data/freenas-v1.db?mode=ro&immutable=1' .dump") do |cfg|
    if cfg.include? "Error: unable to open database"
      cfg = cmd("sudo sqlite3 'file:///data/freenas-v1.db?mode=ro&immutable=1' .dump")
    end
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
