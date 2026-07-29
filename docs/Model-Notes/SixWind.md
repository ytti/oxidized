# 6WIND VSR

## Configuration formats

The SixWind model supports two configuration formats: hierarchical and fullpath.
It stores backups in the hierarchical format by default and collects the
fullpath format as an alternative output. The default format can be swapped,
and the alternative backup format disabled, if required.

The behaviour can be changed with variables:

```yaml
models:
  sixwind:
    vars:
      sixwind_default_storage_type: hierarchical
      sixwind_store_alternative: true
```

`sixwind_default_storage_type` accepts `hierarchical` or `fullpath`. The default
is `hierarchical` when undefined.

`sixwind_store_alternative` accepts the YAML booleans `true` or `false`. The
default is `true` when undefined. When set to `false`, only the default format
is collected.

| Default format | Main configuration command         | Alternative output       |
|----------------|------------------------------------|--------------------------|
| `hierarchical` | `show config nodefault`            | `sixwind-fullpath`       |
| `fullpath`     | `show config nodefault fullpath`   | `sixwind-hierarchical`   |

## Alternative output storage

Alternative configurations use the Oxidized
[output types](/docs/Outputs.md#output-types) feature. By default, each output
type is stored in a separate repository alongside the main repository.

Set `type_as_directory` to store both formats in the same Git repository:

```yaml
output:
  default: git
  git:
    user: Oxidized
    email: user@example.com
    repo: "/var/lib/oxidized/devices.git"
    type_as_directory: true
```

With this setting, alternative configurations are stored beneath the
`sixwind-fullpath` or `sixwind-hierarchical` directory. The normal Oxidized
fetch and Web UI download return only the configured default format. The
alternative format must be retrieved directly from the underlying storage.

## Secret removal

This model uses the standard `remove_secret` variable to replace values
following the `password` or `secret` keywords with `<secret hidden>`. It can be
enabled globally:

```yaml
vars:
  remove_secret: true
```

To enable secret removal for SixWind only, configure it at model scope:

```yaml
models:
  sixwind:
    vars:
      remove_secret: true
```

This includes password or secret commands with an optional numeric type. Other
sensitive values, such as private keys, are not currently removed by the model.

Back to [Model-Notes](README.md)
