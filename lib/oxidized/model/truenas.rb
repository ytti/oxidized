class TrueNAS < Oxidized::Model
  using Refinements

  comment '# '

  cmd('uname -a') { |cfg| comment cfg }
  cmd('cat /etc/version') { |cfg| comment cfg }

  # for TrueNAS SCALE machines, make sure the user you use to connect can run
  # this command, or if needed, with passwordless sudo. Try putting this in
  # /etc/sudoers
  #    oxidized ALL=(ALL) NOPASSWD: /usr/bin/find /mnt/.ix-apps/app_configs *, /usr/bin/sqlite3 -readonly file\:/data/freenas-v1.db *

  cmd("sqlite3 -readonly 'file:/data/freenas-v1.db' .dump") do |cfg|
    if cfg.include? "Error: unable to open database"
      # retry with sudo
      cfg = cmd("sudo sqlite3 -readonly 'file:/data/freenas-v1.db' .dump")
    end
    cfg.lines.reject do |line|
      line.match(/^INSERT INTO storage_replication /) || # ignore storage_replication because repl_status field changes on every run
        line.match(/^INSERT INTO system_alert /) || # ignore system alerts in db
        line.match(/^INSERT INTO sqlite_sequence VALUES\('system_alert',/) || # ignore system alerts in db
        line.match(/^INSERT INTO tasks_cloudsync /) # ignore cloudsync tasks because job field changes on every run
    end.join
  end

  post do
    filter_column("storage_replication", "repl_state")
  end

  post do
    filter_column("tasks_cloudsync", "job")
  end

  post do
    collect_ixapps_configurations
  end

  def filter_column(table_name, column_name)
    sqlite_cmd = "sqlite3 -readonly 'file:/data/freenas-v1.db'"

    # This SQL command will create a SELECT query with all columns except the one we want to skip.
    generate_select_cmd = "select 'select ' || group_concat(name,', ') || ' FROM #{table_name};' FROM pragma_table_info('#{table_name}') WHERE name != '#{column_name}';"

    select_stmt = cmd("#{sqlite_cmd} \"#{generate_select_cmd}\"")
    if select_stmt.include? "Error: unable to open database"
      # retry with sudo
      sqlite_cmd = "sudo #{sqlite_cmd}"
      select_stmt = cmd("#{sqlite_cmd} \"#{generate_select_cmd}\"")
    end

    insert_cmds = "-header '.mode insert #{table_name}' '#{select_stmt}'"
    cmd("#{sqlite_cmd} #{insert_cmds}") do |cfg|
      if cfg.include? "INSERT"
        # Don't add a COMMIT; if the query came up with no rows
        cfg + "COMMIT;\n"
      end
    end
  end

  def collect_ixapps_configurations()
    cmd('if [ -d /mnt/.ix-apps ]; then sudo find /mnt/.ix-apps/app_configs \( -name "app.yaml" -or -name "user_config.yaml" -or -name "metadata.yaml" \) -printf "\n\n#######################\n# %p\n#######################\n" -exec cat {} \; ;else echo "# No Apps configuration found in /mnt/.ix-apps"; fi')
  end

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
