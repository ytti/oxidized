# EatonNetwork Configuration

This model uses the command `save_configuration -p <passphrase>` to get the backup config. The `-p` option is a required passphrase used to encrypted sensitive parts of the config data, the encrypted data is nondeterministic and changes with each run. The passphrase used is the auth password for the node.

See the [Eaton Network-M3 user's guide](https://www.eaton.com/content/dam/eaton/products/backup-power-ups-surge-it-power-distribution/power-management-software-connectivity/eaton-gigabit-network-card/network-m3/resources/eaton-network-m3-user-guide.pdf) section 7.7.14 (page 260) for more information.

To not have the backup change on each for all `eatonnetwork` node run set a model var in the config for the `eatonnetwork` model to [remove secrets](../Configuration.md#removing-secrets):

```yaml
models:
  eatonnetwork:
    vars:
      remove_secret: true
```

See the [Eaton Network-M3 user's guide](https://www.eaton.com/content/dam/eaton/products/backup-power-ups-surge-it-power-distribution/power-management-software-connectivity/eaton-gigabit-network-card/network-m3/resources/eaton-network-m3-user-guide.pdf) section 3.20 (page 111) for details on JSON configuration structure, and restoring without sensitive/secrets.

Back to [Model-Notes](README.md)
