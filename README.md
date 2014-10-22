# Oxidized

Oxidized is a network device configration backup tool. Its a RANCID replacment!

* automatically adds/removes threads to meet configured retrieval interval
* restful API to move node immediately to head-of-queue (GET/POST /node/next/[NODE])
  * syslog udp+file example to catch config change event (ios/junos) and trigger config fetch
  * will signal ios/junos user who made change, which output module can (git does) use (via POST)
  * 'git blame' will show for each line who and when the change was made
* restful API to reload list of nodes (GET /reload)
* restful API to fetch configurations (/node/fetch/[NODE] or /node/fetch/group/[NODE])
* restful API to show list of nodes (GET /nodes)

[Youtube Video: Oxidized TREX 2014 presentation](http://youtu.be/kBQ_CTUuqeU#t=3h)

#### Index
1. [Supported OS Types](#supported-os-types)
2. [Installation](#installation)
    * [Debian](#debian)
    * [CentOS, Oracle Linux, Red Hat Linux version 6](#centos-oracle-linux-red-hat-linux-version 6)
3. [Initial Configuration](#configuration)
4. [Installing Ruby 2.1.2 using RVM](#installing-ruby-2.1.2-using-rvm)
5. [Cookbook](#cookbook)
    * [Debugging](#debugging)
    * [Privileged mode](#privileged-mode)
    * [SQLite Example Configuration](#sqlite-example-configuration)
    * [Default Configuration](#default-configuration)
6. [Ruby API](#ruby-api)
    * [Input](#input)
    * [Output](#output)
    * [Source](#source)
    * [Model](#model)

# Supported OS types

 * A10 Networks ACOS
 * Alcatel-Lucent ISAM 7302/7330
 * Alcatel-Lucent Operating System AOS
 * Alcatel-Lucent Operating System AOS7
 * Alcatel-Lucent Operating System Wireless
 * Alcatel-Lucent TiMOS
 * Arista EOS
 * Brocade Fabric OS
 * Brocade Ironware
 * Brocade NOS (Network Operating System)
 * Brocade Vyatta
 * Cisco AireOS
 * Cisco ASA
 * Cisco IOS
 * Cisco IOS-XR
 * Cisco NXOS
 * Cisco SMB (Nikola series)
 * DELL PowerConnect
 * Extreme Networks XOS
 * Force10 FTOS
 * FortiGate FortiOS
 * HP ProCurve
 * Huawei VRP
 * Juniper JunOS
 * Juniper ScreenOS (Netscreen)
 * Ubiquiti AirOS


# Installation
## Debian
Install all required packages and gems.

```
apt-get install ruby ruby-dev libsqlite3-dev libssl-dev
gem install oxidized
gem install oxidized-script oxidized-web # if you don't install oxidized-web, make sure you remove "rest" from your config
```

## CentOS, Oracle Linux, Red Hat Linux version 6
Install Ruby 1.9.3 or greater (for Ruby 2.1.2 installation instructions see "Installing Ruby 2.1.2 using RVM"), then install Oxidized dependencies
```
yum install cmake sqlite-devel openssl-devel
```

Now lets install oxidized via Rubygems:
```
gem install oxidized
gem install oxidized-script oxidized-web
```

# Configuration

To initialize an empty configuration file, simply run ```oxidized``` once to create a config in you home directory ```~/.config/oxidized/config```. The configuration file is in YAML format.

Create the directory where the ```output``` is going to store configurations:
```
mkdir ~/.config/oxidized/configs
```

Lets tell Oxidized where it finds a list of network devices to backup configuration from. You can either use CSV or SQLite as source. To create a CVS source add the following snippet:

```
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
```

Now lets create a file based device database (you might want to switch to sqlite later on). Put your routers in ```~/.config/oxidized/router.db``` (file format is compatible with rancid). Simply add a item per line:

```
router01.example.com:ios
switch01.example.com:procurve
router02.example.com:ios:admin:S3cre37x
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


## Cookbook
### Debugging
In case a plugin doesn't work correctly, you can enable live debugging of SSH/Telnet sessions. Just add the ```debug``` option, specifying a log file destination to the ```input``` section.

The following example will log an active ssh session to ```/home/fisakytt/.config/oxidized/log_input-ssh``` and telnet to ```log_input-telnet```. The file will be truncated with each newly created session, so you need to put a ```tailf``` or ```tail -f``` on that file.

```
input:
  default: ssh, telnet
  debug: ~/.config/oxidized/log_input
  ssh:
    secure: false
```

### Privileged mode

To put your routers in privileged mode, Oxidized needs to send the enable command. You can globally enable this,
by adding the following snippet to the global configuration file.

```
---
vars:
   enable: S3cre7
```

### SQLite Example Configuration
```
---
username: LANA
password: LANAAAAAAA
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/usr/local/lan/oxidized.git"
source:
  default: sql
  sql:
    adapter: sqlite
    database: "/usr/local/lan/corona.db"
    table: device
    map:
      name: ptr
      model: model
```

### Default Configuration
If you don't configure output and source, it'll further fill them with example configs for your chosen output/source in subsequent runs.

```
---
username: username
password: password
model: junos
interval: 3600
log: ~/.config/oxidized/log
debug: false
threads: 30
timeout: 20
retries: 3
prompt: !ruby/regexp /^([\w.@-]+[#>]\s?)$/
vars: {}
groups: {}
rest: 127.0.0.1:8888
input:
  default: ssh, telnet
  debug: false
  ssh:
    secure: false
output:
  default: file
source:
  default: csv
  csv:
    file: ~/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
model_map:
  cisco: ios
  juniper: junos
```

Output and Source could be:
```
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "~/.config/oxidized/oxidized.git"
source:
  default: csv
  csv:
    file: "~/.config/oxidized/router.db"
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      model: 1
```
which reads nodes from rancid compatible router.db maps their model names to
model names oxidized expects, stores config in git, will try ssh first then
telnet, wont crash on changed ssh keys.

Hopefully most of them are obvious, log is ignored if Syslog::Logger exists
(>=2.0) and syslog is used instead.

System wide configurations can be stored in /etc/oxidized/config, this might be
useful for storing for example source information, if many users are using
oxs/Oxidized::Script, which would allow user specific config only to include
username+password.

# Ruby API

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
 * 'sql' and 'csv' (supports any format with single entry per line, like router.db)

## Model
 * lists commands to gather from given device model
 * can use 'cmd', 'prompt', 'comment', 'cfg'
 * cfg is executed in input/output/source context
 * cmd is executed in instance of model
 * 'junos', 'ios', 'ironware' and 'powerconnect' implemented
