# Configuration

## Modules
The configuration of each module is described in its respective sub-configuration file:
* [Inputs.md](Inputs.md)
* [Outputs.md](Outputs.md)
* [Sources.md](Sources.md)
* [Hooks.md](Hooks.md)

## Privileged mode

To start privileged mode before pulling the configuration, Oxidized needs to
send the enable command. You can globally enable this, by adding the following
snippet to the global section of the configuration file.

```yaml
vars:
   enable: S3cre7
```

## Removing secrets

To strip out secrets from configurations before storing them, Oxidized needs the
`remove_secret` flag. You can globally enable this by adding the following
snippet to the global section of the configuration file.

```yaml
vars:
  remove_secret: true
```

Device models that contain substitution filters to remove sensitive data will
now be run on any fetched configuration.

As a partial example from ios.rb:

```ruby
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    # ...
    cfg
  end
```

The above strips out snmp community strings from your saved configs.

**NOTE:** Removing secrets reduces the usefulness as a full configuration backup, but it may make sharing configs easier.

## Timeout and Time limit
You can configure when oxidized will `timeout` while fetching a configuration
(default: 20 seconds), and how much absolute time (`timelimit`) the fetching
is allowed to last (default: 300 seconds, or 5 minutes):

* `timeout`: Maximum time to wait for a single operation during config fetching.
  Not every input module has an implemented timeout.
* `timelimit`: Maximum total time allowed for the entire fetch job. It is
  independent of input modules and will always be enforced.

If `timelimit`is reached, the fetch job will be killed and will produce a
warning. The job status will be set to `timelimit`.

```yaml
timeout: 20
timelimit: 300
```

## Advanced Configuration

Below is an advanced example configuration.

You will be able to (optionally) override options per device.
The router.db format used is `hostname:model:username:password:enable_password`.
Hostname and model will be the only required options, all others override the
global configuration sections.

Custom model names can be mapped to an oxidized model name with a string or
a regular expression.


```yaml
---
username: oxidized
password: S3cr3tx
model: junos
interval: 3600 #interval in seconds
log: ~/.config/oxidized/log
debug: false
threads: 30 # maximum number of threads
# use_max_threads:
# false - the number of threads is selected automatically based on the interval option, but not more than the maximum
# true - always use the maximum number of threads
use_max_threads: false
timeout: 20
timelimit: 300
retries: 3
prompt: !ruby/regexp /^([\w.@-]+[#>]\s?)$/
crash:
  directory: ~/.config/oxidized/crashes
  hostnames: false
vars:
  enable: S3cr3tx
groups: {}
extensions:
  oxidized-web:
    load: true
    # Bind to any IPv4 interface
    listen: 0.0.0.0
    # Bind to port 8888 (default)
    port: 8888
    # Prefix prod to the URL, so http://oxidized.full.domain/prod/
    url_prefix: prod
    # virtual hosts to listen to (others will be denied)
    vhosts:
      - localhost
      - 127.0.0.1
      - oxidized
      - oxidized.full.domain
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
  !ruby/regexp /procurve/: procurve
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

Model specific variables/credentials within groups

```yaml
groups:
  foo:
    models:
      arista:
        username: admin
        password: password
        vars:
          ssh_keys: "~/.ssh/id_rsa_foo_arista"
      vyatta:
        vars:
          ssh_keys: "~/.ssh/id_rsa_foo_vyatta"
  bar:
    models:
      routeros:
        vars:
          ssh_keys: "~/.ssh/id_rsa_bar_routeros"
      vyatta:
        username: admin
        password: pass
        vars:
          ssh_keys: "~/.ssh/id_rsa_bar_vyatta"
```

For mapping multiple group values to a common name, you can use strings and
regular expressions:

```yaml
group_map:
  alias1: groupA
  alias2: groupA
  alias3: groupB
  alias4: groupB
  !ruby/regexp /specialgroup/: groupS
  aliasN: groupZ
  # ...
```

add group mapping to a source

```yaml
source:
  # ...
  <source>:
    # ...
    map:
      model: 0
      name: 1
      group: 2
```

For model specific credentials

You can add 'username: nil' if the device only expects a Password at prompt.

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
  cisco:
    username: nil
    password: pass
```

## Options (credentials, vars, etc.) precedence:
From least to most important:
- global options
- model specific options
- group specific options
- model specific options in groups
- options defined on single nodes

More important options overwrite less important ones if they are set.

## oxidized-web: RESTful API and web interface

The RESTful API and web interface are enabled by installing the `oxidized-web`
gem and configuring the `extensions.oxidized-web:` section in the configuration
file. You can set the following parameter:
- `load`: `true`/`false`: Enables or disables the `oxidized-web` extension
  (default: `false`)
- `listen`: Specifies the interface to bind to (default: `127.0.0.1`). Valid
  options:
  - `127.0.0.1`: Allows IPv4 connections from localhost only
  - `'[::1]'`: Allows IPv6 connections from localhost only
  - `<IPv4-Address>` or `'[<IPv6-Address>]'`: Binds to a specific interface
  - `0.0.0.0`: Binds to any IPv4 interface
  - `'[::]'`:  Binds to any IPv4 and IPv6 interface
- `port`: Specifies the TCP port to listen to (default: `8888`)
- `url_prefix`: Defines a URL prefix (default: no prefix)
- `vhosts`: A list of virtual hosts to listen to. If not specified, it will
  respond to any virtual host.

> [!NOTE]
> The old syntax `rest: 127.0.0.1:8888/prefix` is still supported but
> deprecated. It produces a warning and won't be suported in future releases.
>
> If the `rest` configuration is used, the extensions.oxidized-web will be
> ignored.

> [!NOTE]
> You need oxidized-web version 0.16.0 or later to use the
> extentions.oxidized-web configuration


```yaml
# Listen on http://[::1]:8888/
extensions:
  oxidized-web:
    load: true
    listen: '[::1]'
    port: 8888
```

```yaml
# Listen on http://127.0.0.1:8888/
extensions:
  oxidized-web:
    load: true
    listen: 127.0.0.1
    port: 8888
```

```yaml
# Listen on http://[2001:db8:0:face:b001:0:dead:beaf]:8888/oxidized/
extensions:
  oxidized-web:
    load: true
    listen: '[2001:db8:0:face:b001:0:dead:beaf]'
    port: 8888
    url_prefix: oxidized
```

```yaml
# Listen on http://10.0.0.1:8000/oxidized/
extensions:
  oxidized-web:
    load: true
    listen: 10.0.0.1
    port: 8000
    url_prefix: oxidized
```

```yaml
# Listen on any interface to http://oxidized.rocks:8888 and
# http://oxidized:8888
extensions:
  oxidized-web:
    load: true
    listen: '[::]'
    url_prefix: oxidized
    vhosts:
     - oxidized.rocks
     - oxidized
```

## Triggered backups

A node can be moved to head-of-queue via the REST API `GET/PUT
/node/next/[NODE]`. This can be useful to immediately schedule a fetch of the
configuration after some other event such as a syslog message indicating a
configuration update on the device.

In the default configuration this node will be processed when the next job
worker becomes available, it could take some time if existing backups are in
progress. To execute moved jobs immediately a new job can be added
automatically:

```yaml
next_adds_job: true
```

This will allow for a more timely fetch of the device configuration.

## Disabling DNS resolution

In some instances it might not be desirable to attempt to resolve names of
nodes. One such use case is when nodes are accessed through an SSH proxy, where
the remote end resolves the names differently than the host on which Oxidized
runs would.

Names can instead be passed verbatim to the input:

```yaml
resolve_dns: false
```

## Environment variables

You can use some environment variables to change default root directories values.

* `OXIDIZED_HOME` may be used to set oxidized configuration directory, which defaults to `~/.config/oxidized`
* `OXIDIZED_LOGS` may be used to set oxidzied logs and crash directories root, which default to `~/.config/oxidized`

## Logging
Oxidized supports parallel logging to different systems (appenders). The
following appenders are currently supported:
- `stderr`: log to standard error (this is the default)
- `stdout`: log to standard output
- `file`: log to a file
- `syslog`: log to syslog

> `stderr` and `stdout` are mutually exclusive and will produce a warning if used
> simultaneously.

> You can configure as many file appenders as you wish.

You can set a log level globally and/or for each appender.
- The global log level will limit which log messages are accepted, depending
  on their level.
  - The default global log level is `:info`.
  - If you set `debug: true` in the configuration, the global log level will be
    forced to `:debug`.
- The appender log level limits which log messages are displayed by the
  appender, depending on their level.
  - The default is `:trace`.


> Available log levels: `:trace`, `:debug`, `:info`, `:warn`,
> `:error` and `:fatal`

Here is a configuration example logging `:error` to syslog, `:warn` to stdout
and `:info` to `~/.config/oxidized/info.log`:

```yaml
logger:
  # Default level
  # level: :info
  appenders:
    - type: syslog
      level: :error
    - type: stdout
      level: :warn
    - type: file
      # Default level is :trace, so we get the logs in the default level (:info)
      file: ~/.config/oxidized/info.log
```

If you want to log :trace to a file and `:info` to stdout, you must set the
global log level to `:trace`, and limit the stdout appender to `:info`:

```yaml
logger:
  level: :trace
  appenders:
    - type: stdout
      level: :info
    - type: file
      file: ~/.config/oxidized/trace.log
```

### Change log level
You can change the global log level of oxidized by sending a SIGUSR2 to
the process:
```
kill -SIGUSR2 424242
```
It will rotate between the log levels and log a warning with the new level
(you won't see the warning when the log level is `:fatal` or `:error`):
```
2025-06-30 15:25:27.972881 W [109750:2640] SemanticLogger -- Changed global default log level to :warn
```

If you specified a log level for an appender, this log level won't be
changed.

> :warning: **Warning** You need oxidized-web 0.17.0 and above for this or
> it will kill the whole oxidized application.

### Dump running threads
With the SIGTTIN signal, oxidized will log a backtrace for each of its threads.
```
kill -SIGTTIN 424242
```

The threads used to fetch the configs are named `Oxidized::Job 'hostname'`:

```
2025-06-30 15:32:22.293047 W [110549:2640 core.rb:76] Thread Dump -- Backtrace:
/home/xxx/oxidized/lib/oxidized/core.rb:76:in `sleep'
/home/xxx/oxidized/lib/oxidized/core.rb:76:in `block in run'
(...)
2025-06-30 15:32:22.293409 W [110549:Oxidized::Job 'host2' ssh.rb:127] Thread Dump -- Backtrace:
/home/xxx/oxidized/lib/oxidized/input/ssh.rb:127:in `sleep'
/home/xxx/oxidized/lib/oxidized/input/ssh.rb:127:in `block (2 levels) in expect'
```
