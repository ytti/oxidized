# State Persistence

Oxidized uses SQLite to persist state information to disk, ensuring data survives application restarts and providing better reliability.

## Overview

Prior to this feature, Oxidized stored all state in memory, which was lost when the application restarted. The new persistent state system stores:

- **Node statistics**: Job execution counts, success/failure rates, execution times
- **Last job information**: Details of the most recent job for each node
- **Modification times**: History of when configurations were last changed
- **Job scheduling data**: Duration history used for optimal job scheduling

## Architecture

### Storage Location

By default, the state database is stored at:
```
~/.config/oxidized/state/oxidized.db
```

You can customize this location by setting the `OXIDIZED_HOME` environment variable.

### Database Structure

The state database uses SQLite with the following features:

- **WAL mode**: Write-Ahead Logging for better concurrency
- **Automatic schema migration**: Database schema is versioned and migrated automatically
- **Secure permissions**: Database files are created with 0600 permissions (owner read/write only)
- **Automatic cleanup**: State for removed nodes is automatically cleaned up

### Tables

1. **node_stats_counters**: Cumulative job statistics per node and status
2. **node_stats_history**: Recent job execution history (limited by history_size)
3. **node_last_jobs**: Most recent job information for each node
4. **node_mtimes**: Modification time history for each node
5. **job_durations**: Recent job durations for scheduling optimization

## Security

### File Permissions

The state persistence system implements several security measures:

1. **Directory permissions**: The state directory is created with 0700 permissions (owner only)
2. **Database file permissions**: Database files are created with 0600 permissions (owner read/write only)
3. **WAL file permissions**: Associated WAL and SHM files are also secured with 0600 permissions

### Data Validation

All data written to the database is validated:

- Node names are validated for length (max 255 characters) and non-empty
- Numeric values are checked for validity (no NaN or Infinity values)
- Time values are properly converted and stored as UTC
- Input parameters are type-checked

## Performance

### Caching

Node statistics are cached in memory for 1 second to reduce database queries during high-frequency operations.

### Database Optimization

- **WAL mode**: Allows concurrent reads while writing
- **NORMAL synchronous mode**: Balances durability and performance
- **Indexed queries**: All common queries use database indexes
- **Batch operations**: Cleanup and trimming operations use efficient bulk queries

### History Limits

History data is automatically trimmed to prevent unbounded growth:

- **Statistics history**: Configurable via `stats.history_size` (default: 10 per status)
- **Modification times**: Same as history_size
- **Job durations**: Limited to the number of nodes

## Configuration

The state persistence system uses existing Oxidized configuration:

```yaml
# History size for statistics (default: 10)
stats:
  history_size: 10
```

No additional configuration is required. The feature is enabled automatically.

## Troubleshooting

### Database Locked Errors

If you encounter "database is locked" errors:

1. Ensure only one Oxidized instance is running
2. Check that no other process has the database file open
3. WAL mode should prevent most lock contention

### Disk Space

The database size is automatically managed through history limits. To manually check database size:

```bash
ls -lh ~/.config/oxidized/state/oxidized.db
```

To reclaim space after removing many nodes:

```sql
sqlite3 ~/.config/oxidized/state/oxidized.db "VACUUM;"
```

### Corruption Recovery

If the database becomes corrupted:

1. Stop Oxidized
2. Backup the corrupted database: `mv ~/.config/oxidized/state/oxidized.db{,.backup}`
3. Restart Oxidized (a new database will be created automatically)
4. Statistics will be rebuilt as jobs execute

### Migration from In-Memory State

When upgrading to this version:

1. Existing in-memory state will be lost on first restart
2. Statistics will rebuild as jobs execute
3. No manual migration is required

## API Reference

The State class is available via `Oxidized.state` and provides the following methods:

### Public Methods

- `get_node_stats(node_name)`: Retrieve all statistics for a node
- `update_node_stats(node_name, job, history_size)`: Update statistics with new job
- `get_last_job(node_name)`: Get the last job for a node
- `set_last_job(node_name, job)`: Set/clear the last job for a node
- `update_mtime(node_name, history_size)`: Record a modification time
- `get_job_durations`: Get all job durations for scheduling
- `add_job_duration(duration, max_size)`: Add a job duration
- `cleanup_removed_nodes(existing_nodes)`: Remove state for deleted nodes
- `reset!`: Clear all state data (testing only)
- `close`: Close database connection

## Best Practices

1. **Backups**: Include `~/.config/oxidized/state/` in your backup strategy
2. **Monitoring**: Monitor database file size and growth
3. **History size**: Tune `stats.history_size` based on your needs
4. **Cleanup**: The automatic cleanup runs during node reloads; trigger manual reloads if removing many nodes

## Technical Details

### Thread Safety

- All database operations use transactions
- Sequel handles connection pooling
- WAL mode allows concurrent readers

### Data Types

- **Timestamps**: Stored as SQLite DATETIME in UTC
- **Durations**: Stored as FLOAT (seconds)
- **Counters**: Stored as INTEGER
- **Node names**: Stored as TEXT (max 255 chars)

### Schema Versioning

The database schema is versioned. Future schema changes will be applied automatically through migrations.

Current schema version: 1
