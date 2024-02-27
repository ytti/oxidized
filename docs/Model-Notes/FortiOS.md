# FortiOS Configuration

Create user oxidized with ED25519 public key

```text
config system admin
edit oxidized
set trusthost1 192.0.2.1 255.255.255.255
set accprofile "super_admin_readonly"
set ssh-public-key1 "ssh-ed25519 AAAAThisIsJustAnExmapleKey_UseYourOxidizedPUBLICKEY oxidized@librenms"
end
```


Fortigate procdues a lot of config changes. I recommend filtering using

```yaml
models:
  fortios:
    vars:
      remove_secret: true
```



Oxidized can now retrieve your configuration!

Back to [Model-Notes](README.md)
