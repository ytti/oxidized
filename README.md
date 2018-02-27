# Oxidized [![Build Status](https://travis-ci.org/Shopify/oxidized.svg)](https://travis-ci.org/Shopify/oxidized) [![Gem Version](https://badge.fury.io/rb/oxidized.svg)](http://badge.fury.io/rb/oxidized) [![Join the chat at https://gitter.im/oxidized/Lobby](https://badges.gitter.im/oxidized/Lobby.svg)](https://gitter.im/oxidized/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

> Is your company using Oxidized and has Ruby developers on staff? I'd love help from an extra maintainer!

[WANTED: MAINTAINER](#help-needed)

Oxidized is a network device configuration backup tool. It's a RANCID replacement!

* Automatically adds/removes threads to meet configured retrieval interval
* Restful API to move node immediately to head-of-queue (GET/POST /node/next/[NODE])
* Syslog udp+file example to catch config change event (ios/junos) and trigger config fetch
  * Will signal ios/junos user who made change, which output modules can use (via POST)
  * The git output module uses this info - 'git blame' will for each line show who made the change and when
* Restful API to reload list of nodes (GET /reload)
* Restful API to fetch configurations (/node/fetch/[NODE] or /node/fetch/group/[NODE])
* Restful API to show list of nodes (GET /nodes)
* Restful API to show list of version for a node (/node/version[NODE]) and diffs

[Youtube Video: Oxidized TREX 2014 presentation](http://youtu.be/kBQ_CTUuqeU#t=3h)

#### Index
1. [Supported OS Types](docs/Supported-OS-Types.md)
2. [Installation](#installation)
    * [Debian](#debian)
    * [CentOS, Oracle Linux, Red Hat Linux](#centos-oracle-linux-red-hat-linux)
    * [FreeBSD](#freebsd)
    * [Build from Git](#build-from-git)
    * [Docker](#running-with-docker)
    * [Installing Ruby 2.1.2 using RVM](#installing-ruby-212-using-rvm)
3. [Initial Configuration](#configuration)
4. [Configuration](docs/Configuration.md)
    * [Debugging](docs/Configuration.md#debugging)
    * [Privileged mode](docs/Configuration.md#privileged-mode)
    * [Disabling SSH exec channels](docs/Configuration.md#disabling-ssh-exec-channels)
    * [Sources:](docs/Sources.md)
        * [Source: CSV](docs/Sources.md#source-csv)
        * [Source: SQL](docs/Sources.md#source-sql)
        * [Source: SQLite](docs/Sources.md#source-sqlite)
        * [Source: Mysql](docs/Sources.md#source-mysql)
        * [Source: HTTP](docs/Sources.md#source-http)
    * [Outputs:](docs/Outputs.md)
        * [Output: GIT](docs/Outputs.md#output-git)
        * [Output: GIT-Crypt](docs/Outputs.md#output-git-crypt)
        * [Output: HTTP](docs/Outputs.md#output-http)
        * [Output: File](docs/Outputs.md#output-file)
        * [Output types](docs/Outputs.md#output-types)
    * [Advanced Configuration](docs/Configuration.md#advanced-configuration)
    * [Advanced Group Configuration](docs/Configuration.md#advanced-group-configuration)
    * [Hooks](docs/Hooks.md)
5. [Help](#help)
6. [Ruby API](docs/Ruby-API.md#ruby-api)
    * [Input](docs/Ruby-API.md#input)
    * [Output](docs/Ruby-API.md#output)
    * [Source](docs/Ruby-API.md#source)
    * [Model](docs/Ruby-API.md#model)

# Installation

## Debian
Install all required packages and gems.

```shell
apt-get install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev
gem install oxidized
gem install oxidized-script oxidized-web # if you don't install oxidized-web, make sure you remove "rest" from your config
```

## CentOS, Oracle Linux, Red Hat Linux
On CentOS 6 / RHEL 6, install Ruby greater than 1.9.3 (for Ruby 2.1.2 installation instructions see [Installing Ruby 2.1.2 using RVM](#installing-ruby-212-using-rvm)), then install Oxidized dependencies

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
[Use RVM to install Ruby v2.1.2](#installing-ruby-2.1.2-using-rvm)

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
this will bind port 8888 to all interfaces then expose port out. [Issue #445](https://github.com/ytti/oxidized/issues/445)

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

create the `/etc/oxidized/router.db` [See CSV Source for further info](docs/Configuration.md#source-csv)

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

# Configuration
Oxidized configuration is in YAML format. Configuration files are subsequently sourced from `/etc/oxidized/config` then `~/.config/oxidized/config`. The hashes will be merged, this might be useful for storing source information in a system wide file and  user specific configuration in the home directory (to only include a staff specific username and password). Eg. if many users are using `oxs`, see [Oxidized::Script](https://github.com/ytti/oxidized-script).

It is recommended practice to run Oxidized using its own username.  This username can be added using standard command-line tools:

```
useradd oxidized
```

> It is recommended __not__ to run Oxidized as root.

To initialize a default configuration in your home directory `~/.config/oxidized/config`, simply run `oxidized` once. If you don't further configure anything from the output and source sections, it'll extend the examples on a subsequent `oxidized` execution. This is useful to see what options for a specific source or output backend are available.

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

Oxidized supports [CSV](docs/Configuration.md#source-csv),  [SQLite](docs/Configuration.md#source-sqlite), [MySQL](docs/Configuration.md#source-mysql) and [HTTP](docs/Configuration.md#source-http) as source backends. The CSV backend reads nodes from a rancid compatible router.db file. The SQLite and MySQL backends will fire queries against a database and map certain fields to model items. The HTTP backend will fire queries against a http/https url. Take a look at the [Configuration](docs/Configuration.md) for more details.

## Outputs

Possible outputs are either [File](docs/Configuration.md#output-file), [GIT](docs/Configuration.md#output-git), [GIT-Crypt](docs/Configuration.md#output-git-crypt) and [HTTP](docs/Configuration.md#output-http). The file backend takes a destination directory as argument and will keep a file per device, with most recent running version of a device. The GIT backend (recommended) will initialize an empty GIT repository in the specified path and create a new commit on every configuration change. The GIT-Crypt backend will also initialize a GIT repository but every configuration push to it will be encrypted on the fly by using `git-crypt` tool. Take a look at the [Configuration](docs/Configuration.md) for more details.

Maps define how to map a model's fields to model [model fields](https://github.com/ytti/oxidized/tree/master/lib/oxidized/model). Most of the settings should be self explanatory, log is ignored if `use_syslog`(requires Ruby >= 2.0) is set to `true`.

First create the directory where the CSV `output` is going to store device configs and start Oxidized once.
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

Now lets create a file based device database (you might want to switch to SQLite later on). Put your routers in `~/.config/oxidized/router.db` (file format is compatible with rancid). Simply add an item per line:

```
router01.example.com:ios
switch01.example.com:procurve
router02.example.com:ios
```

Run `oxidized` again to take the first backups.

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

1. Copy init script from extra/ folder to /etc/init.d/oxidized
2. Setup /var/run/

```
mkdir /var/run/oxidized
chown oxidized:oxidized /var/run/oxidized
```

3. Make oxidized start on boot

```
update-rc.d oxidized defaults
```

# Help

If you need help with Oxidized then we have a few methods you can use to get in touch.

  - [Gitter](https://gitter.im/oxidized/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) - You can join the Lobby on gitter to chat to other Oxidized users.
  - [GitHub](https://github.com/ytti/oxidized/) - For help and requests for code changes / updates.
  - [Forum](https://community.librenms.org/c/help/oxidized) - A user forum run by [LibreNMS](https://github.com/librenms/librenms) where you can ask for help and support.

# Help Needed

As things stand right now, `oxidized` is maintained by a single person. A great
many [contributors](https://github.com/ytti/oxidized/graphs/contributors) have
helped further the software, however contributions are not the same as ongoing
owner- and maintainer-ship. It appears that many companies use the software to
manage their network infrastructure, this is great news! But without additional
help to maintain the software and put out releases, the future of oxidized
might be less bright. The current pace of development and the much needed
refactoring simply are not sustainable if they are to be driven by a single
person.

## Maintainers

If you would like to be a maintainer for Oxidized then please read through the below and see if it's something you would like to help with. It's not a requirement that you can tick all the boxes below but it helps :)

* Triage on issues, review pull requests and help answer any questions from users.
* Above average knowledge of the Ruby programming language.
* Professional experience with both oxidized and some other config backup tool (like rancid).
* Ability to keep a cool head, and enjoy interaction with end users! :)
* A desire and passion to help drive `oxidized` towards its `1.x.x` stage of life
  * Help refactor the code
  * Rework the core infrastructure
* Permission from your employer to contribute to open source projects

## YES, I WANT TO HELP

Awesome! Simply send an email to Saku Ytti <saku@ytti.fi>.

## Further reading

Brian Anderson (from Rust fame) wrote an [excellent
post](http://brson.github.io/2017/04/05/minimally-nice-maintainer) on what it
means to be a maintainer.

# License and Copyright

          Copyright
          2013-2015 Saku Ytti <saku@ytti.fi>
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
