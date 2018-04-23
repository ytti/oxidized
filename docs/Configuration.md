# Configuration

## Debugging

In case a model plugin doesn't work correctly (ios, procurve, etc.), you can enable live debugging of SSH/Telnet sessions. Just add a `debug` option containing the value true to the `input` section. The log files will be created depending on the parent directory of the logfile option.

The following example will log an active ssh/telnet session `/home/oxidized/.config/oxidized/log/<IP-Adress>-<PROTOCOL>`. The file will be truncated on each consecutive ssh/telnet session, so you need to put a `tailf` or `tail -f` on that file!

```yaml
log: /home/oxidized/.config/oxidized/log

...

input:
  default: ssh, telnet
  debug: true
  ssh:
    secure: false
```

## Password Masking in Debug Logs

By default Oxidized will no longer log cleartext passwords in debug logs. This is designed to prevent Oxidized debug logs from containing all of your node authentication information. This makes submitting [GitHub issues for oxidized](https://github.com/ytti/oxidized/issues) and sharing debug logs easier and safer for everyone.

NOTE - This only applies to the configuration of Oxidized itself - NOT any fetched device configurations. Model-specific code is used for model-specific configuration sanitization (see Removing secrets below).

The value for `password` will instead be logged as `********`.

These settings can be controlled by the global section in the Oxidized configuration file.

```yaml
..(other global configuration)...
mask_value: "<Redacted by Security Directive 1234>"
```

If you need to log authentication information in your debug logs you can make the following adjustments:

```yaml
..(other global configuration)...
mask_sensitive: false
```


## Privileged mode

To start privileged mode before pulling the configuration, Oxidized needs to send the enable command. You can globally enable this, by adding the following snippet to the global section of the configuration file.

```yaml
vars:
   enable: S3cre7
```

## Removing secrets

To strip out secrets from configurations before storing them, Oxidized needs the the remove_secrets flag. You can globally enable this by adding the following snippet to the global sections of the configuration file.

```yaml
vars:
  remove_secret: true
```

Device models can contain substitution filters to remove potentially sensitive data from configs.

As a partial example from ios.rb:

```yaml
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    (...)
    cfg
  end
```

The above strips out snmp community strings from your saved configs.

**NOTE:** Removing secrets reduces the usefulness as a full configuration backup, but it may make sharing configs easier.

## Disabling SSH exec channels

Oxidized uses exec channels to make information extraction simpler, but there are some situations where this doesn't work well, e.g. configuring devices. This feature can be turned off by setting the `ssh_no_exec`
variable.

```yaml
vars:
  ssh_no_exec: true
```

## SSH Proxy Command

Oxidized can `ssh` through a proxy as well. To do so we just need to set `ssh_proxy` variable.

```yaml
...
map:
  name: 0
  model: 1
vars_map:
  enable: 2
  ssh_proxy: 3
...
```

## FTP Passive Mode

Oxidized uses ftp passive mode by default. Some devices require passive mode to be disabled. To do so, we can set `input.ftp.passive` to false

```yaml
input:
  ftp:
    passive: false
```

## Advanced Configuration

Below is an advanced example configuration. You will be able to (optionally) override options per device. The router.db format used is `hostname:model:username:password:enable_password`. Hostname and model will be the only required options, all others override the global configuration sections.

```yaml
---
username: oxidized
password: S3cr3tx
model: junos
interval: 3600 #interval in seconds
log: ~/.config/oxidized/log
debug: false
threads: 30
timeout: 20
retries: 3
prompt: !ruby/regexp /^([\w.@-]+[#>]\s?)$/
vars:
  enable: S3cr3tx
groups: {}
rest: 127.0.0.1:8888
pid: ~/.config/oxidized/oxidized.pid
input:
  default: ssh, telnet
  debug: false
  ssh:
    secure: false
output:
  default: git
  git:
      user: Oxidized
      email: oxidized@example.com
      repo: "~/.config/oxidized/oxidized.git"
source:
  default: csv
  csv:
    file: ~/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
      username: 2
      password: 3
    vars_map:
      enable: 4
model_map:
  cisco: ios
  juniper: junos
```

## Advanced Group Configuration

For group specific credentials

```yaml
groups:
  mikrotik:
    username: admin
    password: blank
  ubiquiti:
    username: ubnt
    password: ubnt
```

and add group mapping

```yaml
map:
  model: 0
  name: 1
  group: 2
```

For model specific credentials

```yaml
models:
  junos:
    username: admin
    password: password
  ironware:
    username: admin
    password: password
    vars:
      enable: enablepassword
  apc_aos:
    username: apc
    password: password
```

## RESTful API and Web Interface

The RESTful API and Web Interface is enabled by configuring the `rest:` parameter in the config file.  This parameter can optionally contain a relative URI.

```yaml
# Listen on http://127.0.0.1:8888/
rest: 127.0.0.1:8888
```

```yaml
# Listen on http://10.0.0.1:8000/oxidized/
rest: 10.0.0.1:8000/oxidized
```

## Triggered backups

A node can be moved to head-of-queue via the REST API `GET/POST /node/next/[NODE]`.

In the default configuration this node will be processed when the next job worker becomes available, it could take some time if existing backups are in progress. To execute moved jobs immediately a new job can be added:

```yaml
next_adds_job: true
```
