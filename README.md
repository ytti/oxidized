# Oxidized [![Build Status](https://travis-ci.org/Shopify/oxidized.svg)](https://travis-ci.org/Shopify/oxidized) [![Gem Version](https://badge.fury.io/rb/oxidized.svg)](http://badge.fury.io/rb/oxidized) [![Join the chat at https://gitter.im/oxidized/Lobby](https://badges.gitter.im/oxidized/Lobby.svg)](https://gitter.im/oxidized/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

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
    * [CentOS, Oracle Linux, Red Hat Linux](#centos-oracle-linux-red-hat-linux)
    * [BSD](#freebsd)
3. [Initial Configuration](#configuration)
4. [Installing Ruby 2.1.2 using RVM](#installing-ruby-2.1.2-using-rvm)
5. [Running with Docker](#running-with-docker)
6. [Cookbook](#cookbook)
    * [Debugging](#debugging)
    * [Privileged mode](#privileged-mode)
    * [Disabling SSH exec channels](#disabling-ssh-exec-channels)
    * [Source: CSV](#source-csv)
    * [Source: SQL](#source-sql)
      * [Source: SQLite](#source-sqlite)
      * [Source: Mysql](#source-mysql)
    * [Source: HTTP](#source-http)
    * [Output: GIT](#output-git)
    * [Output: GIT-Crypt](#output-git-crypt)
    * [Output: HTTP](#output-http)
    * [Output: File](#output-file)
    * [Output types](#output-types)
    * [Advanced Configuration](#advanced-configuration)
    * [Advanced Group Configuration](#advanced-group-configuration)
7. [Ruby API](#ruby-api)
    * [Input](#input)
    * [Output](#output)
    * [Source](#source)
    * [Model](#model)

# Supported OS types
 * Vendor
   * OS model

 * A10 Networks
   * [ACOS](lib/oxidized/model/acos.rb)
 * Alcatel-Lucent
   * [AOS](lib/oxidized/model/aos.rb)
   * [AOS7](lib/oxidized/model/aos7.rb)
   * [ISAM](lib/oxidized/model/isam.rb)
   * Wireless
 * Alvarion
   * [BreezeACCESS](lib/oxidized/model/alvarion.rb)
 * APC
   * [AOS](lib/oxidized/model/apc_aos.rb)
 * Arista
   * [EOS](lib/oxidized/model/eos.rb)
 * Arris
   * [C4CMTS](lib/oxidized/model/c4cmts.rb)
 * Aruba
   * [AOSW](lib/oxidized/model/aosw.rb)
 * Brocade
   * [FabricOS](lib/oxidized/model/fabricos.rb)
   * [Ironware](lib/oxidized/model/ironware.rb)
   * [NOS (Network Operating System)](lib/oxidized/model/nos.rb)
   * [Vyatta](lib/oxidized/model/vyatta.rb)
   * [6910](lib/oxidized/model/br6910.rb)
 * Casa
   * [Casa](lib/oxidized/model/casa.rb)
 * Check Point
   * [GaiaOS](lib/oxidized/model/gaiaos.rb)
 * Ciena
   * [SAOS](lib/oxidized/model/saos.rb)
 * Cisco
   * [AireOS](lib/oxidized/model/aireos.rb)
   * [ASA](lib/oxidized/model/asa.rb)
   * [CatOS](lib/oxidized/model/catos.rb)
   * [IOS](lib/oxidized/model/ios.rb)
   * [IOSXR](lib/oxidized/model/iosxr.rb)
   * [NGA](lib/oxidized/model/cisconga.rb)
   * [NXOS](lib/oxidized/model/nxos.rb)
   * [SMB (Nikola series)](lib/oxidized/model/ciscosmb.rb)
 * Citrix
   * [NetScaler (Virtual Applicance)](lib/oxidized/model/netscaler.rb)
 * Coriant (former Tellabs)
   * [TMOS (8800)](lib/oxidized/model/corianttmos.rb)
   * [8600](lib/oxidized/model/coriant8600.rb)
 * Cumulus
   * [Linux](lib/oxidized/model/cumulus.rb)
 * DataCom
   * [DmSwitch 3000](lib/oxidized/model/datacom.rb)
 * DELL
   * [PowerConnect](lib/oxidized/model/powerconnect.rb)
   * [AOSW](lib/oxidized/model/aosw.rb)
 * D-Link
   * [D-Link](lib/oxidized/model/dlink.rb)
 * Ericsson/Redback
   * [IPOS (former SEOS)](lib/oxidized/model/ipos.rb)
 * Extreme Networks
   * [XOS](lib/oxidized/model/xos.rb)
   * [WM](lib/oxidized/model/mtrlrfs.rb)
 * F5
   * [TMOS](lib/oxidized/model/tmos.rb)
 * Force10
   * [DNOS](lib/oxidized/model/dnos.rb)
   * [FTOS](lib/oxidized/model/ftos.rb)
 * FortiGate
   * [FortiOS](lib/oxidized/model/fortios.rb)
 * Fujitsu
   * [PRIMERGY Blade switch 1/10Gbe](lib/oxidized/model/fujitsupy.rb)
 * Hatteras
   * [Hatteras](lib/oxidized/model/hatteras.rb)
 * HP
   * [Comware (HP A-series, H3C, 3Com)](lib/oxidized/model/comware.rb)
   * [Procurve](lib/oxidized/model/procurve.rb)
   * [BladeSystem (Onboard Administrator)](lib/oxidized/model/hpebladesystem.rb)
 * Huawei
   * [VRP](lib/oxidized/model/vrp.rb)
 * Juniper
   * [JunOS](lib/oxidized/model/junos.rb)
   * [ScreenOS (Netscreen)](lib/oxidized/model/screenos.rb)
 * Mellanox
   * [MLNX-OS](lib/oxidized/model/mlnxos.rb)
   * [Voltaire](lib/oxidized/model/voltaire.rb)
 * Mikrotik
   * [RouterOS](lib/oxidized/model/routeros.rb)
 * Motorola
   * [RFS](lib/oxidized/model/mtrlrfs.rb)
 * MRV
   * [MasterOS](lib/oxidized/model/masteros.rb)
   * [FiberDriver](lib/oxidized/model/fiberdriver.rb)
 * Netgear
   * [Netgear](lib/oxidized/model/netgear.rb)
 * Netonix
   * [WISP Switch (As Netonix)](lib/oxidized/model/netonix.rb)
 * Nokia (formerly TiMetra, Alcatel, Alcatel-Lucent)
   * [SR OS (TiMOS)](lib/oxidized/model/timos.rb)
 * OneAccess
   * [OneOS](lib/oxidized/model/oneos.rb)
 * Opengear
   * [Opengear](lib/oxidized/model/opengear.rb)
 * Palo Alto
   * [PANOS](lib/oxidized/model/panos.rb)
 * [PLANET SG/SGS Switches](lib/oxidized/model/planet.rb)
 * [pfSense](lib/oxidized/model/pfsense.rb)
 * Quanta
   * [Quanta / VxWorks 6.6 (1.1.0.8)](lib/oxidized/model/quantaos.rb)
 * Siklu
   * [EtherHaul](lib/oxidized/model/siklu.rb)
 * Supermicro
   * [Supermicro](lib/oxidized/model/supermicro.rb)
 * Trango Systems
   * [Trango](lib/oxidized/model/trango.rb)
 * TPLink
   * [TPLink](lib/oxidized/model/tplink.rb)
 * Ubiquiti
   * [AirOS](lib/oxidized/model/airos.rb)
   * [Edgeos](lib/oxidized/model/edgeos.rb)
   * [EdgeSwitch](lib/oxidized/model/edgeswitch.rb)
 * Watchguard
   * [Fireware OS](lib/oxidized/model/firewareos.rb)
 * Zhone
   * [Zhone (OLT and MX)](lib/oxidized/model/zhoneolt.rb)
 * Zyxel
   * [ZyNOS](lib/oxidized/model/zynos.rb)


# Installation
## Debian
Install all required packages and gems.

```shell
apt-get install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev
gem install oxidized
gem install oxidized-script oxidized-web # if you don't install oxidized-web, make sure you remove "rest" from your config
```

## CentOS, Oracle Linux, Red Hat Linux
On CentOS 6 / RHEL 6, install Ruby greater than 1.9.3 (for Ruby 2.1.2 installation instructions see "Installing Ruby 2.1.2 using RVM"), then install Oxidized dependencies
```shell
yum install cmake sqlite-devel openssl-devel libssh2-devel
```

RHEL 7 / CentOS 7 will work out of the box with the following package list:

```shell
yum install cmake sqlite-devel openssl-devel libssh2-devel ruby gcc ruby-devel
```

Now let's install oxidized via Rubygems:
```shell
gem install oxidized
gem install oxidized-script oxidized-web
```

## FreeBSD
Use RVM to install Ruby v2.1.2

Install all required packages and gems.

```shell
pkg install cmake pkgconf
gem install oxidized
gem install oxidized-script oxidized-web
```



## Build from Git
```shell
git clone https://github.com/ytti/oxidized.git
cd oxidized/
gem build *.gemspec
gem install pkg/*.gem
```

# Configuration

Oxidized configuration is in YAML format. Configuration files are subsequently sourced from ```/etc/oxidized/config``` then ```~/.config/oxidized/config```. The hashes will be merged, this might be useful for storing source information in a system wide file and  user specific configuration in the home directory (to only include a staff specific username and password). Eg. if many users are using ```oxs```, see [Oxidized::Script](https://github.com/ytti/oxidized-script).

It is recommended practice to run Oxidized using its own username.  This username can be added using standard command-line tools:

```
useradd oxidized
```

It is recommended not to run Oxidized as root.

To initialize a default configuration in your home directory ```~/.config/oxidized/config```, simply run ```oxidized``` once. If you don't further configure anything from the output and source sections, it'll extend the examples on a subsequent ```oxidized``` execution. This is useful to see what options for a specific source or output backend are available.

You can set the env variable `OXIDIZED_HOME` to change its home directory.

```
OXIDIZED_HOME=/etc/oxidized

$ tree -L 1 /etc/oxidized
/etc/oxidized/
├── config
├── log-router-ssh
├── log-router-telnet
├── pid
├── router.db
└── repository.git
```

## Source

Oxidized supports ```CSV```, ```SQLite``` and ```HTTP``` as source backends. The CSV backend reads nodes from a rancid compatible router.db file. The SQLite backend will fire queries against a database and map certain fields to model items. The HTTP backend will fire queries against a http/https url. Take a look at the [Cookbook](#cookbook) for more details.

## Outputs

Possible outputs are either ```file```, ```git``` or ```git-crypt```. The file backend takes a destination directory as argument and will keep a file per device, with most recent running version of a device. The GIT backend (recommended) will initialize an empty GIT repository in the specified path and create a new commit on every configuration change. The GIT-Crypt backend will also initialize a GIT repository but every configuration push to it will be encrypted on the fly by using ```git-crypt``` tool. Take a look at the [Cookbook](#cookbook) for more details.

Maps define how to map a model's fields to model [model fields](https://github.com/ytti/oxidized/tree/master/lib/oxidized/model). Most of the settings should be self explanatory, log is ignored if `use_syslog`(requires Ruby >= 2.0) is set to `true`.

First create the directory where the CSV ```output``` is going to store device configs and start Oxidized once.
```
mkdir -p ~/.config/oxidized/configs
oxidized
```

Now tell Oxidized where it finds a list of network devices to backup configuration from. You can either use CSV or SQLite as source. To create a CSV source add the following snippet:

Note: If gpg is set to anything other than false it will attempt to decrypt the file contents
```
source:
  default: csv
  csv:
    file: ~/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    gpg: false
    gpg_password: 'password'
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
yum install bzip2 autoconf automake libtool bison iconv-devel libssh2-devel
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

clone git repo:

```
git clone https://github.com/ytti/oxidized
```

build container locally:

```
docker build -q -t oxidized/oxidized:latest oxidized/
```

create config directory in main system:

```
mkdir /etc/oxidized
```

run container the first time:
_Note: this step in only needed for creating Oxidized's configuration file and can be skipped if you already have it

```
docker run --rm -v /etc/oxidized:/root/.config/oxidized -p 8888:8888/tcp -t oxidized/oxidized:latest oxidized
```
If the RESTful API and Web Interface are enabled, on the docker host running the container
edit /etc/oxidized/config and modify 'rest: 127.0.0.1:8888' by 'rest: 0.0.0.0:8888'
this will bind port 8888 to all interfaces then expose port out. (Issue #445)

You can also use docker-compose to launch oxidized container:
```
# docker-compose.yml
# docker-compose file example for oxidized that will start along with docker daemon
oxidized:
  restart: always
  image: oxidized/oxidized:latest
  ports:
    - 8888:8888/tcp
  environment:
    CONFIG_RELOAD_INTERVAL: 600
  volumes:
    - /etc/oxidized:/root/.config/oxidized
```

create the `/etc/oxidized/router.db`

```
vim /etc/oxidized/router.db
```

run container again:

```
docker run -v /etc/oxidized:/root/.config/oxidized -p 8888:8888/tcp -t oxidized/oxidized:latest
oxidized[1]: Oxidized starting, running as pid 1
oxidized[1]: Loaded 1 nodes
Puma 2.13.4 starting...
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:8888
```

If you want to have the config automatically reloaded (e.g. when using a http source that changes)

```
docker run -v /etc/oxidized:/root/.config/oxidized -p 8888:8888/tcp -e CONFIG_RELOAD_INTERVAL=3600 -t oxidized/oxidized:latest
```

If you need to use an internal CA (e.g. to connect to an private github instance)

```
docker run -v /etc/oxidized:/root/.config/oxidized -v /path/to/MY-CA.crt:/usr/local/share/ca-certificates/MY-CA.crt -p 8888:8888/tcp -e UPDATE_CA_CERTIFICATES=true -t oxidized/oxidized:latest
```

## Cookbook
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
    username: root
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

# Extra

## Ubuntu SystemV init setup

The init script assumes that you have a used named 'oxidized' and that oxidized is in one of the following paths:

```
/sbin
/bin
/usr/sbin
/usr/bin
/usr/local/bin
```

1.)Copy init script from extra/ folder to /etc/init.d/oxidized
2.)Setup /var/run/

```
mkdir /var/run/oxidized
chown oxidized:oxidized /var/run/oxidized
```

3.)Make oxidized start on boot

```
update-rc.d oxidized deafults
```

Note the channel name must be in quotes.

# Ruby API

The following objects exist in Oxidized.

## Input
 * gets config from nodes
 * must implement 'connect', 'get', 'cmd'
 * 'ssh', 'telnet, ftp, and tftp' implemented

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
