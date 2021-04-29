# Netgear Configuration

There are several models available with CLI management via telnet (port 60000). To enable telnet configure device with web interface and set 'Maintenance > Troubleshooting > Remote Diagnostics' to 'enable'. All devices behave like one of the following:

## Older models

```text
Connected to 192.168.3.201.

(GS748Tv4)
Applying Interface configuration, please wait ...admin
Password:********
(GS748Tv4) >enable
Password:

(GS748Tv4) #terminal length 0

(GS748Tv4) #show running-config
```

## Newer models

```text
Connected to 172.0.3.203.

User:admin
Password:********
(GS724Tv4) >enable

(GS724Tv4) #terminal length 0

(GS724Tv4) #show running-config
```

The main differences are:

* the prompt for username is different (looks quite strange for older models)
* enable password
  * the older model prompts for enable password and it expects empty string
  * the newer model does not prompt for enable password at all

Configuration for older/newer models: make sure you have defined variable 'enable':

* `'true'` for newer models
* `''` empty string: for older models

One possible configuration:

## oxidized config

```yaml
source:
  default: csv
  csv:
    file: "/home/oxidized/.config/oxidized/router.db"
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
      username: 2
      password: 3
    vars_map:
      enable: 4
      telnet_port: 5
```

## router.db

```text
switchOldFW:netgear:admin:adminpw::60000
switchNewFW:netgear:admin:adminpw:true:60000
```

Another approach to set parameters:

## oxidized config

```yaml
  netgear:
    vars:
      enable: true
      telnet_port: 60000
```

[Reference](https://github.com/ytti/oxidized/pull/1268)

Back to [Model-Notes](README.md)
