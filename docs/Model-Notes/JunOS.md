# JunOS Configuration

Create login class cfg-view

```text
set system login class cfg-view permissions view-configuration
set system login class cfg-view allow-commands "(show)|(set cli screen-length)|(set cli screen-width)"
set system login class cfg-view deny-commands "(clear)|(file)|(file show)|(help)|(load)|(monitor)|(op)|(request)|(save)|(set)|(start)|(test)"
set system login class cfg-view deny-configuration all
```

Create a user with cfg-view class

```text
set system login user oxidized class cfg-view
set system login user oxidized authentication plain-text-password "verysecret"
```

The commands Oxidized executes are:

1. set cli screen-length 0
2. set cli screen-width 0
3. show configuration
4. show version
5. show chassis hardware
6. show system license
7. show system license keys (ex22|ex33|ex4|ex8|qfx only)
8. show virtual-chassis (MX960 only)
9. show chassis fabric reachability

Oxidized can now retrieve your configuration!

Back to [Model-Notes](README.md)
