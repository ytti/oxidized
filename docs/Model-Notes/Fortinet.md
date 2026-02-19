# Fortinet models
There are two models for Fortinet devices:
- fortigate: for the FortiGate firewalls
- fortios: for VM-Based appliances (FortiManager, FortiADC, FortiAnalyzer...)

# Notes for both models
## Configuration changes / hiding passwords
Fortigate and Fortios re-encrypt their passwords every time the configuration is shown.
This results in a lot of apparent configuration changes on every pull.

To avoid this, you have two options:
- remove secrets
- save significant changes only

### Remove secrets
If you don't want to have a new version every time the configuration is
downloaded, you can hide all secrets. Beware that you won't have a full backup, as all passwords will be replaced with <configuration removed>

```yaml
models:
  fortigate:
    vars:
      remove_secret: true
```

### Save significant changes only
You can [store the configuration only on significant changes](/docs/Configuration.md#store-configuration-only-on-significant-changes)
by setting the [variable](#options-credentials-vars-etc-precedence)
`output_store_mode` to `on_significant`. On FortiGate and FortiOS, this
prevents Oxidized from saving a configuration when there were only changes to
the encrypted passwords. Beware that you won't have the last backup if you only
changed a password.

```yaml
vars:
  output_store_mode: on_significant
```

# Notes for the FortiGate model
## Create user oxidized with ED25519 public key
You can use a user/password for retrieving the configuration or use a SSH public key:

```text
config system admin
edit oxidized
set trusthost1 192.0.2.1 255.255.255.255
set accprofile "super_admin_readonly"
set ssh-public-key1 "ssh-ed25519 AAAAThisIsJustAnExampleKey_UseYourOxidizedPUBLICKEY oxidized@librenms"
end
```

## config vs. full config
On FortiGate, you can get a configuration without default values (`show`) or
including all default values (`show full-configuration`).

The full configuration can be long and may cause timeouts.
Starting with with oxidized 0.30.1, the default is to get the short configuration.

If you need the full configuration, you can activate it in oxidized config file:
```yaml
models:
  fortigate:
    vars:
      fullconfig: true
```
## Autoupdate
You can get the result of `diagnose autoupdate version` by setting the [variable](#options-credentials-vars-etc-precedence) `fortigate_autoupdate` to `true`:

```yaml
vars:
  fortigate_autoupdate: true
```

Note that the variable `fortios_autoupdate` is deprecated and will be removed
in a future Version of Oxidized. Use `fortigate_autoupdate` instead.