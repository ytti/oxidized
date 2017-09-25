## Configuration
### Debugging
In case a model plugin doesn't work correctly (ios, procurve, etc.), you can enable live debugging of SSH/Telnet sessions. Just add a ```debug``` option containing the value true to the ```input``` section. The log files will be created depending on the parent directory of the logfile option.

The following example will log an active ssh/telnet session ```/home/oxidized/.config/oxidized/log/<IP-Adress>-<PROTOCOL>```. The file will be truncated on each consecutive ssh/telnet session, so you need to put a ```tailf``` or ```tail -f``` on that file!

```
log: /home/oxidized/.config/oxidized/log

...

input:
  default: ssh, telnet
  debug: true
  ssh:
    secure: false
```

### Privileged mode

To start privileged mode before pulling the configuration, Oxidized needs to send the enable command. You can globally enable this, by adding the following snippet to the global section of the configuration file.

```
vars:
   enable: S3cre7
```

### Removing secrets

To strip out secrets from configurations before storing them, Oxidized needs the the remove_secrets flag. You can globally enable this by adding the following snippet to the global sections of the configuration file.

```
vars:
  remove_secret: true
```

Device models can contain substitution filters to remove potentially sensitive data from configs.

As a partial example from ios.rb:

```
  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    (...)
    cfg
  end
```
The above strips out snmp community strings from your saved configs.

**NOTE:** Removing secrets reduces the usefulness as a full configuration backup, but it may make sharing configs easier.

### Disabling SSH exec channels

Oxidized uses exec channels to make information extraction simpler, but there are some situations where this doesn't work well, e.g. configuring devices.  This feature can be turned off by setting the ```ssh_no_exec```
variable.

```
vars:
  ssh_no_exec: true
```

### SSH Proxy Command

Oxidized can `ssh` through a proxy as well. To do so we just need to set `ssh_proxy` variable.

```
...
map:
  name: 0
  model: 1
vars_map:
  enable: 2
  ssh_proxy: 3
...
```

## Source

### Source: CSV

One line per device, colon seperated. If `ip` isn't present, a DNS lookup will be done against `name`.  For large installations, setting `ip` will dramatically reduce startup time.

```
source:
  default: csv
  csv:
    file: /var/lib/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      ip: 1
      model: 2
      username: 3
      password: 4
    vars_map:
      enable: 5
```

Example csv `/var/lib/oxidized/router.db`:

```
rtr01.local,192.168.1.1,ios,oxidized,5uP3R53cR3T,T0p53cR3t
```

### Source: SQL
 Oxidized uses the `sequel` ruby gem. You can use a variety of databases that aren't explicitly listed. For more information visit https://github.com/jeremyevans/sequel Make sure you have the correct adapter!
### Source: MYSQL

```sudo apt-get install libmysqlclient-dev```

The values correspond to your fields in the DB such that ip, model, etc are field names in the DB

```
source:
  default: sql
  sql:
    adapter: mysql2
    database: oxidized
    table: nodes
    user: root
    password: rootpass
    map:
      name: ip
      model: model
      username: username
      password: password
    vars_map:
      enable: enable
```

### Source: SQLite

One row per device, filtered by hostname.

```
source:
  default: sql
  sql:
    adapter: sqlite
    database: "/var/lib/oxidized/devices.db"
    table: devices
    map:
      name: fqdn
      model: model
      username: username
      password: password
    vars_map:
      enable: enable
```

### Source: HTTP

One object per device.

HTTP Supports basic auth, configure the user and pass you want to use under the http: section.

```
source:
  default: http
  http:
    url: https://url/api
    scheme: https
    delimiter: !ruby/regexp /:/
    user: username
    pass: password
    map:
      name: hostname
      model: os
      username: username
      password: password
    vars_map:
      enable: enable
    headers:
      X-Auth-Token: 'somerandomstring'
```

You can also pass `secure: false` if you want to disable ssl certificate verification:

```
source:
  default: http
  http:
    url: https://url/api
    scheme: https
    secure: false
```

## Output

### Output: File

Parent directory needs to be created manually, one file per device, with most recent running config.

```
output:
  file:
    directory: /var/lib/oxidized/configs
```

### Output: Git

This uses the rugged/libgit2 interface. So you should remember that normal Git hooks will not be executed.

For a single repositories for all devices:

``` yaml
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/devices.git"
```

And for groups repositories:

``` yaml
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/git-repos/default.git"
```

Oxidized will create a repository for each group in the same directory as the `default.git`. For
example:

``` csv
host1:ios:first
host2:nxos:second
```

This will generate the following repositories:

``` bash
$ ls /var/lib/oxidized/git-repos

default.git first.git second.git
```

If you would like to use groups and a single repository, you can force this with the `single_repo` config.

``` yaml
output:
  default: git
  git:
    single_repo: true
    repo: "/var/lib/oxidized/devices.git"

```

### Output: Git-Crypt

This uses the gem git and system git-crypt interfaces. Have a look at [GIT-Crypt](https://www.agwa.name/projects/git-crypt/) documentation to know how to install it.
Additionally to user and email informations, you have to provide the users ID that can be a key ID, a full fingerprint, an email address, or anything else that uniquely identifies a public key to GPG (see "HOW TO SPECIFY A USER ID" in the gpg man page).


For a single repositories for all devices:

``` yaml
output:
  default: gitcrypt
  gitcrypt:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/devices"
    users:
      - "0x0123456789ABCDEF"
      - "<user@example.com>"
```

And for groups repositories:

``` yaml
output:
  default: gitcrypt
  gitcrypt:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/git-repos/default"
    users:
      - "0xABCDEF0123456789"
      - "0x0123456789ABCDEF"
```

Oxidized will create a repository for each group in the same directory as the `default`. For
example:

``` csv
host1:ios:first
host2:nxos:second
```

This will generate the following repositories:

``` bash
$ ls /var/lib/oxidized/git-repos

default.git first.git second.git
```

If you would like to use groups and a single repository, you can force this with the `single_repo` config.

``` yaml
output:
  default: gitcrypt
  gitcrypt:
    single_repo: true
    repo: "/var/lib/oxidized/devices"
    users:
      - "0xABCDEF0123456789"
      - "0x0123456789ABCDEF"

```

Please note that user list is only updated once at creation.

### Output: Http

POST a config to the specified URL

```
output:
  default: http
  http:
    user: admin
    password: changeit
    url: "http://192.168.162.50:8080/db/coll"
```

### Output types

If you prefer to have different outputs in different files and/or directories, you can easily do this by modifying the corresponding model. To change the behaviour for IOS, you would edit `lib/oxidized/model/ios.rb` (run `gem contents oxidized` to find out the full file path).

For example, let's say you want to split out `show version` and `show inventory` into separate files in a directory called `nodiff` which your tools will not send automated diffstats for. You can apply a patch along the lines of

```
-  cmd 'show version' do |cfg|
-    comment cfg.lines.first
+  cmd 'show version' do |state|
+    state.type = 'nodiff'
+    state

-  cmd 'show inventory' do |cfg|
-    comment cfg
+  cmd 'show inventory' do |state|
+    state.type = 'nodiff'
+    state
+  end

-  cmd 'show running-config' do |cfg|
-    cfg = cfg.each_line.to_a[3..-1].join
-    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
-    cfg.sub! /^(ntp clock-period).*/, '! \1'
-    cfg.gsub! /^\ tunnel\ mpls\ traffic-eng\ bandwidth[^\n]*\n*(
+  cmd 'show running-config' do |state|
+    state = state.each_line.to_a[3..-1].join
+    state.gsub! /^Current configuration : [^\n]*\n/, ''
+    state.sub! /^(ntp clock-period).*/, '! \1'
+    state.gsub! /^\ tunnel\ mpls\ traffic-eng\ bandwidth[^\n]*\n*(
                   (?:\ [^\n]*\n*)*
                   tunnel\ mpls\ traffic-eng\ auto-bw)/mx, '\1'
-    cfg
+    state = Oxidized::String.new state
+    state.type = 'nodiff'
+    state
```

which will result in the following layout

```
diff/$FQDN--show_running_config
nodiff/$FQDN--show_version
nodiff/$FQDN--show_inventory
```

### RESTful API and Web Interface

The RESTful API and Web Interface is enabled by configuring the `rest:` parameter in the config file.  This parameter can optionally contain a relative URI.

```
# Listen on http://127.0.0.1:8888/
rest: 127.0.0.1:8888
```

```
# Listen on http://10.0.0.1:8000/oxidized/
rest: 10.0.0.1:8000/oxidized
```

### Advanced Configuration

Below is an advanced example configuration. You will be able to (optionally) override options per device. The router.db format used is ```hostname:model:username:password:enable_password```. Hostname and model will be the only required options, all others override the global configuration sections.

```
---
username: oxidized
password: S3cr3tx
model: junos
interval: 3600
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

### Advanced Group Configuration

For group specific credentials

```
groups:
  mikrotik:
    username: admin
    password: blank
  ubiquiti:
    username: ubnt
    password: ubnt
```
and add group mapping
```
map:
  model: 0
  name: 1
  group: 2
```
For model specific credentials

```
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

### Triggered backups

A node can be moved to head-of-queue via the REST API `GET/POST /node/next/[NODE]`.

In the default configuration this node will be processed when the next job worker becomes available, it could take some time if existing backups are in progress. To execute moved jobs immediately a new job can be added:

```
next_adds_job: true
```

# Hooks
You can define arbitrary number of hooks that subscribe different events. The hook system is modular and different kind of hook types can be enabled.

## Configuration
Following configuration keys need to be defined for all hooks:

  * `events`: which events to subscribe. Needs to be an array. See below for the list of available events.
  * `type`: what hook class to use. See below for the list of available hook types.

### Events
  * `node_success`: triggered when configuration is succesfully pulled from a node and right before storing the configuration.
  * `node_fail`: triggered after `retries` amount of failed node pulls.
  * `post_store`: triggered after node configuration is stored (this is executed only when the configuration has changed).
  * `nodes_done`: triggered after finished fetching all nodes.

## Hook type: exec
The `exec` hook type allows users to run an arbitrary shell command or a binary when triggered.

The command is executed on a separate child process either in synchronous or asynchronous fashion. Non-zero exit values cause errors to be logged. STDOUT and STDERR are currently not collected.

Command is executed with the following environment:
```
OX_EVENT
OX_NODE_NAME
OX_NODE_IP
OX_NODE_FROM
OX_NODE_MSG
OX_NODE_GROUP
OX_JOB_STATUS
OX_JOB_TIME
OX_REPO_COMMITREF
OX_REPO_NAME
```

Exec hook recognizes following configuration keys:

  * `timeout`: hard timeout for the command execution. SIGTERM will be sent to the child process after the timeout has elapsed. Default: 60
  * `async`: influences whether main thread will wait for the command execution. Set this true for long running commands so node pull is not blocked. Default: false
  * `cmd`: command to run.


## Hook configuration example
```
hooks:
  name_for_example_hook1:
    type: exec
    events: [node_success]
    cmd: 'echo "Node success $OX_NODE_NAME" >> /tmp/ox_node_success.log'
  name_for_example_hook2:
    type: exec
    events: [post_store, node_fail]
    cmd: 'echo "Doing long running stuff for $OX_NODE_NAME" >> /tmp/ox_node_stuff.log; sleep 60'
    async: true
    timeout: 120
```

### githubrepo

This hook configures the repository `remote` and _push_ the code when the specified event is triggerd. If the `username` and `password` are not provided, the `Rugged::Credentials::SshKeyFromAgent` will be used.

`githubrepo` hook recognizes following configuration keys:

  * `remote_repo`: the remote repository to be pushed to.
  * `username`: username for repository auth.
  * `password`: password for repository auth.
  * `publickey`: publickey for repository auth.
  * `privatekey`: privatekey for repository auth.

When using groups repositories, each group must have its own `remote` in the `remote_repo` config.

``` yaml
hooks:
  push_to_remote:
    remote_repo:
      routers: git@git.intranet:oxidized/routers.git
      switches: git@git.intranet:oxidized/switches.git
      firewalls: git@git.intranet:oxidized/firewalls.git
```


## Hook configuration example

``` yaml
hooks:
  push_to_remote:
    type: githubrepo
    events: [post_store]
    remote_repo: git@git.intranet:oxidized/test.git
    username: user
    password: pass
```

## Hook type: awssns

The `awssns` hook publishes messages to AWS SNS topics. This allows you to notify other systems of device configuration changes, for example a config orchestration pipeline. Multiple services can subscribe to the same AWS topic.

Fields sent in the message:

  * `event`: Event type (e.g. `node_success`)
  * `group`: Group name
  * `model`: Model name (e.g. `eos`)
  * `node`: Device hostname

Configuration example:

``` yaml
hooks:
  hook_script:
    type: awssns
    events: [node_fail,node_success,post_store]
    region: us-east-1
    topic_arn: arn:aws:sns:us-east-1:1234567:oxidized-test-backup_events
```

AWS SNS hook requires the following configuration keys:

  * `region`: AWS Region name
  * `topic_arn`: ASN Topic reference

Your AWS credentials should be stored in `~/.aws/credentials`.

## Hook type: slackdiff

The `slackdiff` hook posts colorized config diffs to a [Slack](http://www.slack.com) channel of your choice. It only triggers for `post_store` events.

You will need to manually install the `slack-api` gem on your system:

```
gem install slack-api
```

Configuration example:

``` yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "#network-changes"
```

Note the channel name must be in quotes.
