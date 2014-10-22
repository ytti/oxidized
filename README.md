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
    * [Source: CSV](#source-csv)
    * [Source: SQLite](#source-sqlite)
    * [Output: GIT](#output-git)
    * [Output: File](#output-file)
    * [Advanced Configuration](#advanced-configuration)
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

```shell
apt-get install ruby ruby-dev libsqlite3-dev libssl-dev
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

Oxidized supports ```CSV``` and ```SQLite``` as source backends. The CSV backend reads nodes from a rancid compatible router.db file. The SQLite backend will fire queries against a database and map certain fields to model items. Take a look at the [Cookbook](#cookbook) for more details.

## Outputs

Possible outputs are either ```file``` or ```git```. The file backend takes a destination directory as argument and will keep a file per device, with most recent running version of a device. The GIT backend (recommended) will initialize an empty GIT repository in the specified path and create a new commit on every configuration change. Take a look at the [Cookbook](#cookbook) for more details.

Maps define how to map a model's fields to model [model fields](https://github.com/ytti/oxidized/tree/master/lib/oxidized/model). Most of the settings should be self explanatory, log is ignored if Syslog::Logger exists (>=2.0) and syslog is used instead.

First create the directory where the CSV ```output``` is going to store device configs and start Oxidized once.
```
mkdir ~/.config/oxidized/configs
oxidized
```

Now tell Oxidized where it finds a list of network devices to backup configuration from. You can either use CSV or SQLite as source. To create a CVS source add the following snippet:

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


## Cookbook
### Debugging
In case a model plugin doesn't work correctly (ios, procurve, etc.), you can enable live debugging of SSH/Telnet sessions. Just add a ```debug``` option, specifying a log file destination to the ```input``` section.

The following example will log an active ssh session to ```/home/fisakytt/.config/oxidized/log_input-ssh``` and telnet to ```log_input-telnet```. The file will be truncated on each consecutive ssh/telnet session, so you need to put a ```tailf``` or ```tail -f``` on that file!

```
input:
  default: ssh, telnet
  debug: ~/.config/oxidized/log_input
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
      enable: 3
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
      enable: enable
```

### Output: File

Parent directory needs to be created manually, one file per device, with most recent running config.

```
output:
  file:
    directory: /var/lib/oxidized/configs
```

### Output: Git

```
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/devices.git"
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
      enable: 4
model_map:
  cisco: ios
  juniper: junos
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
 * 'sql' and 'csv' (supports any format with single entry per line, like router.db)

## Model
 * lists commands to gather from given device model
 * can use 'cmd', 'prompt', 'comment', 'cfg'
 * cfg is executed in input/output/source context
 * cmd is executed in instance of model
 * 'junos', 'ios', 'ironware' and 'powerconnect' implemented
