# Lantronix IT Management Gateway OS (ITMGOS)

The `itmgos` model backs up Lantronix console servers and gateways that run the IT
Management Gateway OS CLI: SLC 8000, SLC 9000, EMG 8500/7500 and SLB.

The configuration is the device's own export, `admin config commands copypaste`: a list
of CLI commands that the device restores with `admin config batch`. The model answers the
export's confirmation prompt, and adds `admin version` (hardware, firmware, installed
modules) as comments, without the uptime and last-boot lines.

## Authentication

SLC 9000 units accept SSH logins only through keyboard-interactive authentication, which Oxidized
doesn't try by default. Enable it for the model:

```yaml
models:
  itmgos:
    vars:
      auth_methods: [ "none", "publickey", "password", "keyboard-interactive" ]
```

## Secrets

The export prints passwords, community strings and other secrets in cleartext. Set
`remove_secret: true` (as a var, for the model or globally) so the model replaces them before
the configuration is stored:

- secrets the export writes on the two lines after their command, such as
  `set tacacs+ secret`, `set snmp v3password`, `set ldap bindpassword`, `admin ftp password`,
  `set site chapsecret <site>` and the per-port and USB modem CHAP and dial-out passwords
- SNMP read, write and trap communities, including the community of trap event actions
- local user password hashes

## Session

On login the model runs `set cli terminallines disable` to turn off paging. This is a CLI
setting of the user Oxidized logs in as.

Tested on an SLC 9016 (SLC9016-16U-16E) with firmware 9.7.0.0R21.
