# TrueNAS

This should support both older TrueNAS CORE (FreeBSD-based) and newer
TrueNAS SCALE (Linux-based) devices.

## Authentication

Ensure that the user configured for oxidized to login to your device has the
permissions to read the configuration database. On older CORE instances, this
would just work without sudo. On newer devices, the `/data/freenas-v1.db` file
can only be read by the root user.

On SCALE devices with Apps support, it's also necessary to add some privileges
to read the container configurations for any apps you have installed, which can
be found under `/mnt/.ix-apps`.

You can make sure that the user that oxidized uses to login (`oxidized` in this
example) can dump the configuration using `sudo` by adding something like this
to your `/etc/sudoers` file:

```
oxidized ALL=(ALL) NOPASSWD: /usr/bin/find /mnt/.ix-apps/app_configs *, /usr/bin/sqlite3 -readonly file\:/data/freenas-v1.db *
```
