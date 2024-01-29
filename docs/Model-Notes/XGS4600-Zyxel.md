# ZynOS Configuration

## FTP

FTP access is only possible as admin, other users can login but cannot pull the files.
For the XGS4600 series the config file is _config_ and not _config-0_

To enable FTP backup, uncomment the following line in _oxidized/lib/oxidized/model/zynos.rb_
```text
  # cmd 'config-0'
```

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

## SSH/TelNet

Below is the table from the XGS4600 CLI Reference Guide (Version 3.79~4.50 Edition 1, 07/2017)
Take this table with a pinch of salt, level 3 will not allow _show running-config_!

Privilege Level | Types of commands at this privilege level
----------------|-------------------------------------------
0|Display basic system information.
3|Display configuration or status.
13|Configure features except for login accounts, SNMP user accounts, the authentication method sequence and authorization settings, multiple logins, administrator and enable passwords, and configuration information display.
14|Configure login accounts, SNMP user accounts, the authentication method sequence and authorization settings, multiple logins, and administrator and enable passwords, and display configuration information.

Oxidized can now retrieve your configuration!

Back to [Model-Notes](README.md)
