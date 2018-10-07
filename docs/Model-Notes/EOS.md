# Arista EOS Configuration

By default, EOS requires the `keyboard-interactive` SSH authentication method for a successful SSH login. To add support for this method to your Oxidized configuration, see the [SSH Auth Methods](../Configuration.md#ssh-auth-methods) directive.

It is also possible to modify the EOS configuration to accept the `password` method which Oxidized presents by default. To do so, the following configuration statement can be used:

```text
management ssh
   authentication mode password
```

Back to [Model-Notes](README.md)
