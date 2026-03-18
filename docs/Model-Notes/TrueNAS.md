# TrueNAS

This should support both older TrueNAS CORE (FreeBSD-based) and newer
TrueNAS SCALE (Linux-based) devices.

## Authentication

Ensure that the user configured for oxidized to login to your device has the
permissions to read the configuration database. On older devices, this would
just work.

On newer devices, the `/data/freenas-v1.db` file can only be read by the
root user. You can make sure that the user that oxidized uses to login
(`oxidized` in this example) can dump the configuration using `sudo` by
adding something like this to your `/etc/sudoers` file:

```
oxidized ALL=(ALL) NOPASSWD: /usr/bin/sqlite3 file\:///data/freenas-v1.db?mode\=ro&immutable\=1 .dump
```
