# Huawei SmartAX GPON/EPON/DOCSIS network access devices

It is necessary to disable SSH keepalives in Oxidized for configuration retrieval via SSH to work properly.

To disable SSH keepalives globally edit the config's vars section and add:

```yaml
vars:
  ssh_no_keepalive: true
```

To disable SSH keepalives per device edit the config's source section and map ssh_no_keepalive to a column inside router.db file.

```yaml
source:
  default: csv
  csv:
    file: ~/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
      username: 2
      password: 3
    vars_map:
      ssh_no_keepalive: 4
```

```text
# router.db
10.0.0.1:smartax:someusername:somepassword:true
10.0.0.2:ios:someusername:somepassword:false
```

Back to [Model-Notes](README.md)
