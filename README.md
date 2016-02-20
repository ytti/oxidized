# Oxidized [![Build Status](https://travis-ci.org/Shopify/oxidized.svg)](https://travis-ci.org/Shopify/oxidized)

[![Gem Version](https://badge.fury.io/rb/oxidized.svg)](http://badge.fury.io/rb/oxidized)

Oxidized is a network device configuration backup tool. It's a RANCID replacement!

* automatically adds/removes threads to meet configured retrieval interval
* restful API to move node immediately to head-of-queue (GET/POST /node/next/[NODE])
  * syslog udp+file example to catch config change event (ios/junos) and trigger config fetch
  * will signal ios/junos user who made change, which output modules can use (via POST)
  * The git output module uses this info - 'git blame' will for each line show who made the change and when
* restful API to reload list of nodes (GET /reload)
* restful API to fetch configurations (/node/fetch/[NODE] or /node/fetch/group/[NODE])
* restful API to show list of nodes (GET /nodes)
* restful API to show list of version for a node (/node/version[NODE]) and diffs

[Youtube Video: Oxidized TREX 2014 presentation](http://youtu.be/kBQ_CTUuqeU#t=3h)

#### Index
1. [Supported OS Types](#supported-os-types)
2. [Installation](#installation)
    * [Debian](#debian)
    * [CentOS, Oracle Linux, Red Hat Linux version 6](#centos-oracle-linux-red-hat-linux-version 6)
3. [Initial Configuration](#configuration)
4. [Installing Ruby 2.1.2 using RVM](#installing-ruby-2.1.2-using-rvm)
5. [Running with Docker](#running-with-docker)
6. [Cookbook](#cookbook)
    * [Debugging](#debugging)
    * [Privileged mode](#privileged-mode)
    * [Source: CSV](#source-csv)
    * [Source: SQLite](#source-sqlite)
    * [Source: HTTP](#source-http)
    * [Output: GIT](#output-git)
    * [Output: File](#output-file)
    * [Output types](#output-types)
    * [Advanced Configuration](#advanced-configuration)
7. [Ruby API](#ruby-api)
    * [Input](#input)
    * [Output](#output)
    * [Source](#source)
    * [Model](#model)

# Supported OS types

 * A10 Networks
   * ACOS
 * Alcatel-Lucent
   * AOS
   * AOS7
   * ISAM
   * TiMOS
   * Wireless
 * Arista
   * EOS
 * Arris
   * C4CMTS
 * Aruba
   * AOSW
 * Brocade
   * FabricOS
   * Ironware
   * NOS (Network Operating System)
   * Vyatta
 * Ciena
   * SOAS
 * Cisco
   * AireOS
   * ASA
   * IOS
   * IOSXR
   * NXOS
   * SMB (Nikola series)
 * Cumulus
   * Linux
 * DELL
   * PowerConnect
   * AOSW
 * Ericsson/Redback
   * IPOS (former SEOS)
 * Extreme Networks
   * XOS
   * WM
 * F5
   * TMOS
 * Force10
   * DNOS
   * FTOS
 * FortiGate
   * FortiOS
 * HP
   * Comware (HP A-series, H3C, 3Com)
   * Procurve
 * Huawei
   * VRP
 * Juniper
   * JunOS
   * ScreenOS (Netscreen)
 * Mikrotik
   * RouterOS
 * Motorola
   * RFS
 * MRV
   * MasterOS
 * Opengear
   * Opengear
 * Palo Alto
   * PANOS
 * Ubiquiti
   * AirOS
   * Edgeos
   * EdgeSwitch
 * Zyxel
   * ZyNOS


# Installation
## Debian
Install all required packages and gems.

```shell
apt-get install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake
gem install oxidized
gem install oxidized-script oxidized-web # if you don't install oxidized-web, make sure you remove "rest" from your config
```

## CentOS, Oracle Linux, Red Hat Linux version 6
Install Ruby 1.9.3 or greater (for Ruby 2.1.2 installation instructions see "Installing Ruby 2.1.2 using RVM"), then install Oxidized dependencies
```shell
yum install cmake sqlite-devel openssl-devel
```

Now lets install oxidized via Rubygems:
```shell
gem install oxidized
gem install oxidized-script oxidized-web
```

# Configuration

Oxidized configuration is in YAML format. Configuration files are subsequently sourced from ```/etc/oxidized/config``` then ```~/.config/oxidized/config```. The hashes will be merged, this might be useful for storing source information in a system wide file and  user specific configuration in the home directory (to only include a staff specific username and password). Eg. if many users are using ```oxs```, see [Oxidized::Script](https://github.com/ytti/oxidized-script).

To initialize a default configuration in your home directory ```~/.config/oxidized/config```, simply run ```oxidized``` once. If you don't further configure anything from the output and source sections, it'll extend the examples on a subsequent ```oxidized``` execution. This is useful to see what options for a specific source or output backend are available.

## Source

Oxidized supports ```CSV```, ```SQLite``` and ```HTTP``` as source backends. The CSV backend reads nodes from a rancid compatible router.db file. The SQLite backend will fire queries against a database and map certain fields to model items. The HTTP backend will fire queries against a http/https url. Take a look at the [Cookbook](#cookbook) for more details.

## Outputs

Possible outputs are either ```file``` or ```git```. The file backend takes a destination directory as argument and will keep a file per device, with most recent running version of a device. The GIT backend (recommended) will initialize an empty GIT repository in the specified path and create a new commit on every configuration change. Take a look at the [Cookbook](#cookbook) for more details.

Maps define how to map a model's fields to model [model fields](https://github.com/ytti/oxidized/tree/master/lib/oxidized/model). Most of the settings should be self explanatory, log is ignored if `use_syslog`(requires Ruby >= 2.0) is set to `true`.

First create the directory where the CSV ```output``` is going to store device configs and start Oxidized once.
```
mkdir -p ~/.config/oxidized/configs
oxidized
```

Now tell Oxidized where it finds a list of network devices to backup configuration from. You can either use CSV or SQLite as source. To create a CSV source add the following snippet:

```
source:
  default: csv
  csv:
    file: ~/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
```

Now lets create a file based device database (you might want to switch to SQLite later on). Put your routers in ```~/.config/oxidized/router.db``` (file format is compatible with rancid). Simply add an item per line:

```
router01.example.com:ios
switch01.example.com:procurve
router02.example.com:ios
```

Run ```oxidized``` again to take the first backups.

# Installing Ruby 2.1.2 using RVM

Install Ruby 2.1.2 build dependencies
```
yum install curl gcc-c++ patch readline readline-devel zlib zlib-devel
yum install libyaml-devel libffi-devel openssl-devel make cmake
yum install bzip2 autoconf automake libtool bison iconv-devel
```

Install RVM
```
curl -L get.rvm.io | bash -s stable
```

Setup RVM environment and compile and install Ruby 2.1.2 and set it as default
```
source /etc/profile.d/rvm.sh
rvm install 2.1.2
rvm use --default 2.1.2
```

# Running with Docker
1. clone git repo:

```
    root@bla:~# git clone https://github.com/ytti/oxidized
```
2. build container locally:
```
    root@bla:~# docker build -q -t oxidized/oxidized:latest oxidized/
```
3. create config directory in main system:
```
    root@bla~:# mkdir /etc/oxidized
```
4. run container the first time:
```
    root@bla:~# docker run -v /etc/oxidized:/root/.config/oxidized -p 8888:8888/tcp -t oxidized/oxidized:latest oxidized
```
5. add 'router.db' to /etc/oxidized:
```
    root@bla:~# vim /etc/oxidized/router.db
    [ ... ]
    root@bla:~#
```
6. run container again:
```
    root@bla:~# docker run -v /etc/oxidized:/root/.config/oxidized -p 8888:8888/tcp -t oxidized/oxidized:latest
    oxidized[1]: Oxidized starting, running as pid 1
    oxidized[1]: Loaded 1 nodes
    Puma 2.13.4 starting...
    * Min threads: 0, max threads: 16
    * Environment: development
    * Listening on tcp://0.0.0.0:8888
    ^C

    root@bla:~#
```

If you want to have the config automatically reloaded (e.g. when using a http source that changes)
```
    root@bla:~# docker run -v /etc/oxidized:/root/.config/oxidized -p 8888:8888/tcp -e CONFIG_RELOAD_INTERVAL=3600 -t oxidized/oxidized:latest
```

## Cookbook
### Debugging
In case a model plugin doesn't work correctly (ios, procurve, etc.), you can enable live debugging of SSH/Telnet sessions. Just add a ```debug``` option, specifying a log file destination to the ```input``` section.

The following example will log an active ssh session to ```/home/fisakytt/.config/oxidized/log_input-ssh``` and telnet to ```log_input-telnet```. The file will be truncated on each consecutive ssh/telnet session, so you need to put a ```tailf``` or ```tail -f``` on that file!

```
input:
  default: ssh, telnet
  debug: /tmp/oxidized_log_input
  ssh:
    secure: false
```

### Privileged mode

To start privileged mode before pulling the configuration, Oxidized needs to send the enable command. You can globally enable this, by adding the following snippet to the global section of the configuration file.

```
vars:
   enable: S3cre7
```

### Source: CSV

One line per device, colon seperated.

```
source:
  default: csv
  csv:
    file: /var/lib/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
      username: 2
      password: 3
    vars_map:
      enable: 4
```

### SSH Proxy Command

Oxidized can `ssh` through a proxy as well. To do so we just need to set `proxy` variable.

```
...
map:
  name: 0
  model: 1
vars_map:
  enable: 2
  proxy: 3
...
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

### Output: File

Parent directory needs to be created manually, one file per device, with most recent running config.

```
output:
  file:
    directory: /var/lib/oxidized/configs
```

### Output: Git

This uses the rugged/libgit2 interface. So you should remember that normal Git hooks will not be executed.

```
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/devices.git"
```

### Output types

If you prefer to have different outputs in different files and/or directories, you can easily do this by modifying the corresponding model. To change the behaviour for IOS, you would edit `lib/oxidized/model/ios.rb`.

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

Below is an advanced example configuration. You will be able to (optinally) override options per device. The router.db format used is ```hostname:model:username:password:enable_password```. Hostname and model will be the only required options, all others override the global configuration sections.

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
pid: /var/run/oxidized.pid
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

## Hook type: exec
The `exec` hook type allows users to run an arbitrary shell command or a binary when triggered.

The command is executed on a separate child process either in synchronous or asynchronous fashion. Non-zero exit values cause errors to be logged. STDOUT and STDERR are currently not collected.

Command is executed with the following environment:
```
OX_EVENT
OX_NODE_NAME
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

# Ruby API

The following objects exist in Oxidized.

## Input
 * gets config from nodes
 * must implement 'connect', 'get', 'cmd'
 * 'ssh' and 'telnet' implemented

## Output
 * stores config
 * must implement 'store' (may implement 'fetch')
 * 'git' and 'file' (store as flat ascii) implemented

## Source
 * gets list of nodes to poll
 * must implement 'load'
 * source can have 'name', 'model', 'group', 'username', 'password', 'input', 'output', 'prompt'
   * name - name of the devices
   * model - model to use ios/junos/xyz, model is loaded dynamically when needed (Also default in config file)
   * input - method to acquire config, loaded dynamically as needed (Also default in config file)
   * output - method to store config, loaded dynamically as needed (Also default in config file)
   * prompt - prompt used for node (Also default in config file, can be specified in model too)
 * 'sql', 'csv' and 'http' (supports any format with single entry per line, like router.db)

## Model
 * lists commands to gather from given device model
 * can use 'cmd', 'prompt', 'comment', 'cfg'
 * cfg is executed in input/output/source context
 * cmd is executed in instance of model
 * 'junos', 'ios', 'ironware' and 'powerconnect' implemented


# License and Copyright

Copyright 2013-2015 Saku Ytti <saku@ytti.fi>
          2013-2015 Samer Abdel-Hafez <sam@arahant.net>


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
