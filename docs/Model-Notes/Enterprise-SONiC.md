# Enterprise SONiC

The `enterprise_sonic` model collects the configuration through `sonic-cli`.
By default, the SSH account is expected to log directly into that CLI.

For accounts that log into the Linux shell, set `admin: true`. This established
variable selects the login context; it does not grant privileges. The model
enters `sonic-cli` and exits both the CLI and Linux shell after collection.

To additionally collect the live CONFIG_DB as a separate JSON output, opt in
with `config_db_backup: true`:

```yaml
models:
  enterprise_sonic:
    vars:
      admin: true
      config_db_backup: true
```

This runs `show runningconfiguration all` from the Linux shell without `sudo`.
The output type and name are both `json`. It is only collected when both
variables are `true`; direct-to-CLI accounts cannot use this option. See
[output types](../Creating-Models.md#advanced-feature-output-type) for storage
configuration.
