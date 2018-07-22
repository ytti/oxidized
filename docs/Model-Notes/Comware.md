# Comware Configuration

If you find 3Com Comware devices aren't being backed up this may be due to prompt detection not matching because a previous login message is disabled after the first prompt.

You can disable this on the devices themselves by running this command:

```text
info-center source default channel 1 log state off debug state off
```

[Reference](https://github.com/ytti/oxidized/issues/1171)

Back to [Model-Notes](README.md)
