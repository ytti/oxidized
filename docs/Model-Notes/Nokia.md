# Nokia

## ISAM

### SSH keepalives

Nokia ISAM might require disabling SSH keepalives.

[Reference](https://github.com/ytti/oxidized/issues/1482)

## SR OS

### Model-driven CLI

The `srosmd` model collects configuration using the model-driven CLI in Nokia
SR OS (starting from version 16.1.R1).

## SR Linux

### Configuration output

The model collects only the flat configuration by default. Set the
`srlinux_config_format` variable to select the configuration commands:

| Value | Commands |
|-------|----------|
| `flat` (default) | `info flat` |
| `json` | `info \| as json` |
| `both` | Both commands |

For example, to collect only JSON:

```yaml
vars:
  srlinux_config_format: json
```

With `both`, JSON is marked with the `srlinux-json` output type and the name
`json` for separate storage by output backends that support multiple output
types. With `json`, JSON is the primary configuration output. Device metadata
is still collected as comments in the primary output.

#### Difference in configuration types

`info flat system name`
```
set / system
set / system name
set / system name domain-name example.com
set / system name host-name leaf1
```

`info | as json`
```
{
  "system": {
    "name": {
      "domain-name": "example.com",
      "host-name": "leaf1"
    }
  }
}
```

Back to [Model-Notes](README.md)
