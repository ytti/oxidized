# FortiOS Configuration

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


## Configuration changes / hiding passwords
Fortigate reencrypts its passwords every time the configuration is shown.
This produces a lot of config changes.
If you don't want to have a new version every time the configuration is
downloaded, you can hide all secrets. Beware that you won't have a full backup,
as all passwords will be replaced with <configuration removed>

```yaml
models:
  fortios:
    vars:
      remove_secret: true
```

## config vs. full config
On fortios, you can get a configuration without default values (`show .`) or
including all the default values (`show full-configuration`).

The full configuration can be quite long and produce time-outs.
Beginning with oxidized 0.30.1, the default is to get the short configuration.

If you need the full configuration, you can activate it in oxidized config file:
```yaml
models:
  fortios:
    vars:
      fullconfig: true
```

