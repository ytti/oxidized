ZynOS Configuration
===================

## FTP

FTP access is only possible as admin, other users can login but cannot pull the files.
For the XGS4600 series the config file is _config_ and not _config-0_

The following line in _oxidized/lib/oxidized/model/zynos.rb_ will need changing

```text
  cmd 'config-0'
```

The inclusion of an extra ftp option is also require. Within _input_ add the following

```yaml
input:
  ftp:
    passive: false
```

Oxidized can now retrieve your configuration!

Back to [Model-Notes](README.md)
