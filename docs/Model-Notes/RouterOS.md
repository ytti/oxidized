# Mikrotik RouterOS Configuration

RouterOS 7.12 and later support ED25519 keys. 

Create a key pair, save the public key (``id_ed25519.pub``) and save it on flash. Create a user
and attach the public key.

```text
[admin@mikrotik] > /user add name=oxidized group=read disabled=no
[admin@mikrotik] > /user ssh-keys import public-key-file=id_ed25519.pub user=oxidized
```

Oxidized can now retrieve your configuration!

Back to [Model-Notes](README.md)
