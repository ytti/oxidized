# Nokia

## SR OS

### Nokia ISAM and SSH keepalives

Nokia ISAM might require disabling SSH keepalives.

[Reference](https://github.com/ytti/oxidized/issues/1482)

Back to [Model-Notes](README.md)

### Model-driven CLI in Nokia SR OS (starting from versions 16.1.R1)
New model `srosmd` is introduced which collects information in model-driven format.

## SR Linux

### Configuration output

It is possible to get the configuration output as JSON by setting `srlinux_output_json` as `true`.

By default the model returns the data as the flat `set /`, and the `srlinux_output_json` is `false`

#### Example usage

```
vars:
    srlinux_output_json: true
```

#### Difference in configuration types

`info flat system name`
```
set / system
set / system name
set / system name domain-name example.com
set / system name host-name leaf1
```

`info system name | as json`
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
