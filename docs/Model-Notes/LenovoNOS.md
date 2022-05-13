# Lenovo Network OS

## Remove unstable lines

Some configuration lines change each time you issue the `show running-config` command. These are strings with user passwords and keys (TACACS, RADIUS, etc). In order not to create many elements in the configuration history, these changing lines can be replaced with a stub line. This is what the `remove_unstable_lines` variable is for. Configuration example:

```yaml
vars:
  remove_unstable_lines: true
```

Alternatively map a column for the `remove_unstable_lines` variable.

```yaml
source:
  csv:
    map:
      name: 0
      ip: 1
      model: 2
      group: 3
    vars_map:
      remove_unstable_lines: 4
```

If the value of the variable is `true`, then changing lines will be replaced with a `<unstable line hidden>` stub. Otherwise, the configuration will be saved unchanged. The default value of the variable is `false`.

Back to [Model-Notes](README.md)

