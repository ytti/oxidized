# Mikrotik RouterOS Configuration

RouterOS 7.12 and later support ED25519 keys. 

Create a key pair, save the public key (``id_ed25519.pub``) and save it on flash. Create a user
and attach the public key.

```text
[admin@mikrotik] > /user add name=oxidized group=read disabled=no
[admin@mikrotik] > /user ssh-keys import public-key-file=id_ed25519.pub user=oxidized
```

Oxidized can now retrieve your configuration!

## Save significant changes only

You can [store the configuration only on significant changes](/docs/Configuration.md#store-configuration-only-on-significant-changes)
by setting the [variable](/docs/Configuration.md#options-credentials-vars-etc-precedence)
`output_store_mode` to `on_significant`. On RouterOS, this prevents Oxidized from saving a
new configuration version when only the system history has changed without any actual
configuration change.

```yaml
vars:
  output_store_mode: on_significant
```

Back to [Model-Notes](README.md)
