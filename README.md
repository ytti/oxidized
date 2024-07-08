# Oxidized

[![Build Status](https://github.com/ytti/oxidized/actions/workflows/ruby.yml/badge.svg)](https://github.com/ytti/oxidized/actions/workflows/ruby.yml)
[![codecov.io](https://codecov.io/gh/ytti/oxidized/coverage.svg?branch=master)](https://codecov.io/gh/ytti/oxidized?branch=master)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/5a90cb22db6a4d5ea23ad0dfb53fe03a)](https://www.codacy.com/app/ytti/oxidized?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ytti/oxidized&amp;utm_campaign=Badge_Grade)
[![Code Climate](https://codeclimate.com/github/ytti/oxidized/badges/gpa.svg)](https://codeclimate.com/github/ytti/oxidized)
[![Gem Version](https://badge.fury.io/rb/oxidized.svg)](http://badge.fury.io/rb/oxidized)
[![Join the chat at https://gitter.im/oxidized/Lobby](https://badges.gitter.im/oxidized/Lobby.svg)](https://gitter.im/oxidized/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Oxidized is a network device configuration backup tool. It's a RANCID replacement!

It is light and extensible and supports over 130 operating system types.

Feature highlights:

* Automatically adds/removes threads to meet configured retrieval interval
* Restful API to a move node immediately to head-of-queue (GET/POST /node/next/[NODE])
* Syslog udp+file example to catch config change events (IOS/JunOS) and trigger a config fetch
  * Will signal which IOS/JunOS user made the change, can then be used by output modules (via POST)
  * The `git` output module uses this info - 'git blame' will show who changed each line
* Restful API to reload list of nodes (GET /reload)
* Restful API to fetch configurations (/node/fetch/[NODE] or /node/fetch/group/[NODE])
* Restful API to show list of nodes (GET /nodes)
* Restful API to show list of version for a node (/node/version[NODE]) and diffs

Check out the [Oxidized TREX 2014 presentation](http://youtu.be/kBQ_CTUuqeU?t=3h) video on YouTube!

> :warning: [Maintainer Wanted!](#help-needed) :warning:
>
> Is your company using Oxidized and has Ruby developers on staff? I'd love help from an extra maintainer!

## Index

1. [Supported OS Types](docs/Supported-OS-Types.md)
2. [Installation](#installation)
    * [Debian and Ubuntu](#debian-and-ubuntu)
    * [CentOS, Oracle Linux, Red Hat Linux](#centos-oracle-linux-red-hat-linux)
    * [FreeBSD](#freebsd)
    * [Build from Git](#build-from-git)
    * [Docker](#running-with-docker)
    * [Podman-Compose](#running-with-podman-compose)
    * [Installing Ruby 2.3 using RVM](#installing-ruby-23-using-rvm)
3. [Initial Configuration](#configuration)
4. [Configuration](docs/Configuration.md)
    * [Debugging](docs/Configuration.md#debugging)
    * [Privileged mode](docs/Configuration.md#privileged-mode)
    * [Disabling SSH exec channels](docs/Configuration.md#disabling-ssh-exec-channels)
    * [Sources](docs/Sources.md)
      * [Source: CSV](docs/Sources.md#source-csv)
      * [Source: SQL](docs/Sources.md#source-sql)
      * [Source: SQLite](docs/Sources.md#source-sqlite)
      * [Source: Mysql](docs/Sources.md#source-mysql)
      * [Source: HTTP](docs/Sources.md#source-http)
    * [Outputs](docs/Outputs.md)
      * [Output: GIT](docs/Outputs.md#output-git)
      * [Output: GIT-Crypt](docs/Outputs.md#output-git-crypt)
      * [Output: HTTP](docs/Outputs.md#output-http)
      * [Output: File](docs/Outputs.md#output-file)
      * [Output types](docs/Outputs.md#output-types)
    * [Advanced Configuration](docs/Configuration.md#advanced-configuration)
    * [Advanced Group Configuration](docs/Configuration.md#advanced-group-configuration)
    * [Hooks](docs/Hooks.md)
      * [Hook: exec](docs/Hooks.md#hook-type-exec)
      * [Hook: githubrepo](docs/Hooks.md#hook-type-githubrepo)
      * [Hook: awssns](docs/Hooks.md#hook-type-awssns)
      * [Hook: slackdiff](docs/Hooks.md#hook-type-slackdiff)
      * [Hook: xmppdiff](docs/Hooks.md#hook-type-xmppdiff)
      * [Hook: ciscosparkdiff](docs/Hooks.md#hook-type-ciscosparkdiff)
5. [Creating and Extending Models](docs/Creating-Models.md)
6. [Help](#help)
7. [Help Needed](#help-needed)
8. [Ruby API](docs/Ruby-API.md#ruby-api)
    * [Input](docs/Ruby-API.md#input)
    * [Output](docs/Ruby-API.md#output)
    * [Source](docs/Ruby-API.md#source)
    * [Model](docs/Ruby-API.md#model)

## Installation

### Debian and Ubuntu

Debian "buster" or newer and Ubuntu 17.10 (artful) or newer are recommended. On Ubuntu, begin by enabling the `universe`
repository (required for libssh2-1-dev):

```shell
add-apt-repository universe
```

Install the dependencies:

```shell
apt-get install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev libicu-dev zlib1g-dev g++ libyaml-dev
```

Finally, install the gems:

```shell
gem install oxidized
gem install oxidized-script oxidized-web # If you don't install oxidized-web, ensure "rest" is removed from your Oxidized config.
```

### CentOS, Oracle Linux, Red Hat Linux

On CentOS 6 and 7 / RHEL 6 and 7, begin by installing Ruby 3.1 via RVM by following the instructions:

Make sure you dont have any leftover ruby:
```yum erase ruby```

Then, install gpg key and rvm

```shell
sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm requirements run
rvm install 3.1
rvm use 3.1
```

Install oxidized requirements:
```yum install make cmake which sqlite-devel openssl-devel libssh2-devel gcc libicu-devel gcc-c++```

Install the gems:
```gem install oxidized oxidized-web```

You need to wrap the gem and reference the wrap in the systemctl service file:
```rvm wrapper oxidized```

You can see where the wrapped gem is via
```rvm wrapper show oxidized```
Use that path in the oxidized.service file, restart the systemctl daemon, run oxidized by hand once, edit config file, start service.

### FreeBSD

[Use RVM to install Ruby v2.3](#installing-ruby-23-using-rvm), then install all required packages and gems:

```shell
pkg install cmake pkgconf
gem install oxidized
gem install oxidized-script oxidized-web
```

Oxidized is also available via [FreeBSD ports](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=203374):

```shell
pkg install rubygem-oxidized rubygem-oxidized-script rubygem-oxidized-web
```

### Build from Git

```shell
git clone https://github.com/ytti/oxidized.git
cd oxidized/
gem install bundler
rake install
```

### Running with Docker

Currently, Docker Hub automatically builds the master branch for linux/amd64 and linux/arm64 platforms as [oxidized/oxidized](https://hub.docker.com/r/oxidized/oxidized/), you can make use of this container or build your own.

To build your own, clone git repo:

```shell
git clone https://github.com/ytti/oxidized
```

Then, build the container locally (requires docker 17.05.0-ce or higher):

```shell
docker build -q -t oxidized/oxidized:latest oxidized/
```

Once you've built the container (or chosen to make use of the automatically built container in Docker Hub, which will be downloaded for you by docker on the first `run` command had you not built it), proceed as follows:

Create a configuration directory in the host system:

```shell
mkdir /etc/oxidized
```

Run the container for the first time to initialize the config:

_Note: this step in only required for creating the Oxidized configuration file and can be skipped if you already have one._

```shell
docker run --rm -v /etc/oxidized:/home/oxidized/.config/oxidized -p 8888:8888/tcp --user oxidized -t oxidized/oxidized:latest oxidized
```

If the RESTful API and Web Interface are enabled, on the docker host running the container
edit `/etc/oxidized/config` and modify `rest: 127.0.0.1:8888` to `rest: 0.0.0.0:8888`. This will bind port 8888 to all interfaces, and expose the port so that it could be accessed externally. [(Issue #445)](https://github.com/ytti/oxidized/issues/445)

Alternatively, you can use docker-compose to launch the oxidized container:

```yaml
# docker-compose.yml
# docker-compose file example for oxidized that will start along with docker daemon
---
version: "3"
services:
  oxidized:
    restart: always
    image: oxidized/oxidized:latest
    ports:
      - 8888:8888/tcp
    environment:
      CONFIG_RELOAD_INTERVAL: 600
    volumes:
       - config:/home/oxidized/.config/oxidized/
volumes:
  config:
```

Create the `/etc/oxidized/router.db` (see [CSV Source](docs/Sources.md#source-csv) for further info):

```shell
vim /etc/oxidized/router.db
```

Run container again to start oxidized with your configuration:

```shell
docker run -v /etc/oxidized:/home/oxidized/.config/oxidized -p 8888:8888/tcp -t oxidized/oxidized:latest
oxidized[1]: Oxidized starting, running as pid 1
oxidized[1]: Loaded 1 nodes
Puma 2.13.4 starting...
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:8888
```

If you want to have the config automatically reloaded (e.g. when using a http source that changes):

```shell
docker run -v /etc/oxidized:/home/oxidized/.config/oxidized -p 8888:8888/tcp -e CONFIG_RELOAD_INTERVAL=3600 -t oxidized/oxidized:latest
```

If you need to use an internal CA (e.g. to connect to an private github instance):

```shell
docker run -v /etc/oxidized:/home/oxidized/.config/oxidized -v /path/to/MY-CA.crt:/usr/local/share/ca-certificates/MY-CA.crt -p 8888:8888/tcp -e UPDATE_CA_CERTIFICATES=true -t oxidized/oxidized:latest
```

### Running with podman-compose
Under [examples/podman-compose](examples/podman-compose), you will find a complete
example of how to integrate the container into a docker-compose.yml file.

### Installing Ruby 2.3 using RVM

Install Ruby 2.3 build dependencies

```shell
yum install curl gcc-c++ patch readline readline-devel zlib zlib-devel
yum install libyaml-devel libffi-devel openssl-devel make cmake
yum install bzip2 autoconf automake libtool bison iconv-devel libssh2-devel libicu-devel
```

Install RVM

```shell
curl -L get.rvm.io | bash -s stable
```

Setup RVM environment and compile and install Ruby 2.3 and set it as default

```shell
source /etc/profile.d/rvm.sh
rvm install 2.3
rvm use --default 2.3
```

## Configuration

Oxidized configuration is in YAML format. Configuration files are subsequently sourced from `/etc/oxidized/config` then `~/.config/oxidized/config`. The hashes will be merged, this might be useful for storing source information in a system wide file and  user specific configuration in the home directory (to only include a staff specific username and password). Eg. if many users are using `oxs`, see [Oxidized::Script](https://github.com/ytti/oxidized-script).

It is recommended practice to run Oxidized using its own username.  This username can be added using standard command-line tools:

```shell
useradd -s /bin/bash -m oxidized
```

> It is recommended __not__ to run Oxidized as root.

To initialize a default configuration in your home directory `~/.config/oxidized/config`, simply run `oxidized` once. If you don't further configure anything from the output and source sections, it'll extend the examples on a subsequent `oxidized` execution. This is useful to see what options for a specific source or output backend are available.

You can set the env variable `OXIDIZED_HOME` to change its home directory.

```shell
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

Maps define how to map a model's fields to model [model fields](https://github.com/ytti/oxidized/tree/master/lib/oxidized/model). Most of the settings should be self explanatory, log is ignored if `use_syslog` is set to `true`.

First create the directory where the CSV `output` is going to store device configs and start Oxidized once.

```shell
mkdir -p ~/.config/oxidized/configs
oxidized
```

Now tell Oxidized where it finds a list of network devices to backup configuration from. You can either use CSV or SQLite as source. To create a CSV source add the following snippet:

```yaml
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

```text
router01.example.com:ios
switch01.example.com:procurve
router02.example.com:ios
```

Run `oxidized` again to take the first backups.

## Extra

### Ubuntu init setup

The systemd service assumes that you have a user named 'oxidized' and that oxidized is in one of the following paths:

```text
/sbin
/bin
/usr/sbin
/usr/bin
/usr/local/bin
```

1. Copy systemd service file from extra/ folder to /etc/systemd/system

```shell
sudo cp extra/oxidized.service /etc/systemd/system
```

2. Setup `/var/run/`

```shell
mkdir /run/oxidized
chown oxidized:oxidized /run/oxidized
```

3. Make oxidized start on boot

```shell
sudo systemctl enable oxidized.service
```

## Help

If you need help with Oxidized then we have a few methods you can use to get in touch.

* [Gitter](https://gitter.im/oxidized/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) - You can join the Lobby on gitter to chat to other Oxidized users.
* [GitHub](https://github.com/ytti/oxidized/) - For help and requests for code changes / updates.
* [Forum](https://community.librenms.org/c/help/oxidized) - A user forum run by [LibreNMS](https://github.com/librenms/librenms) where you can ask for help and support.

## Help Needed

As things stand right now, `oxidized` is maintained by very few people.
We would appreciate more individuals and companies getting involved in Oxidized.

Beyond software development, documentation or maintenance of Oxidized, you could
become a model maintainer, which can be done with little burden and would be a
big help to the community.

Interested? Have a look at [CONTRIBUTING.md](CONTRIBUTING.md).

## License and Copyright

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
