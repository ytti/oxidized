# Configuration

## Debugging

In case a model plugin doesn't work correctly (ios, procurve, etc.), you can enable live debugging of SSH/Telnet sessions. Just add a `debug` option containing the value true to the `input` section. The log files will be created depending on the parent directory of the logfile option.

The following example will log an active ssh/telnet session `/home/oxidized/.config/oxidized/log/<IP-Address>-<PROTOCOL>`. The file will be truncated on each consecutive ssh/telnet session, so you need to put a `tailf` or `tail -f` on that file!

```yaml
log: /home/oxidized/.config/oxidized/log

...

input:
  default: ssh, telnet
  debug: true
  ssh:
    secure: false
```

## Privileged mode

To start privileged mode before pulling the configuration, Oxidized needs to send the enable command. You can globally enable this, by adding the following snippet to the global section of the configuration file.

```yaml
vars:
   enable: S3cre7
```

## Removing secrets

To strip out secrets from configurations before storing them, Oxidized needs the `remove_secret` flag. You can globally enable this by adding the following snippet to the global section of the configuration file.

```yaml
vars:
  remove_secret: true
```

Device models that contain substitution filters to remove sensitive data will now be run on any fetched configuration.

As a partial example from ios.rb:

```ruby
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

## SSH Auth Methods

By default, Oxidized registers the following auth methods: `none`, `publickey` and `password`. However you can configure this globally, by groups, models or nodes.

```yaml
vars:
    auth_methods: [ "none", "publickey", "password", "keyboard-interactive" ]
```

## SSH Proxy Command

Oxidized can `ssh` through a proxy as well. To do so we just need to set `ssh_proxy` variable with the proxy host information.

This can be provided on a per-node basis by mapping the proper fields from your source.

An example for a `csv` input source that maps the 4th field as the `ssh_proxy` value.

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

Oxidized uses ftp passive mode by default. Some devices require passive mode to be disabled. To do so, we can set `input.ftp.passive` to false - this will make use of FTP active mode.

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

A node can be moved to head-of-queue via the REST API `GET/POST /node/next/[NODE]`. This can be useful to immediately schedule a fetch of the configuration after some other event such as a syslog message indicating a configuration update on the device.

In the default configuration this node will be processed when the next job worker becomes available, it could take some time if existing backups are in progress. To execute moved jobs immediately a new job can be added automatically:

```yaml
next_adds_job: true
```

This will allow for a more timely fetch of the device configuration.

## Disabling DNS resolution

In some instances it might not be desirable to attempt to resolve names of nodes. One such use case is when nodes are accessed through an SSH proxy, where the remote end resolves the names differently than the host on which Oxidized runs would.

Names can instead be passed verbatim to the input:

```yaml
resolve_dns: false
```
