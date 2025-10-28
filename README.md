# Oxidized

[![Build Status](https://github.com/ytti/oxidized/actions/workflows/ruby.yml/badge.svg)](https://github.com/ytti/oxidized/actions/workflows/ruby.yml)
[![Gem Version](https://badge.fury.io/rb/oxidized.svg)](http://badge.fury.io/rb/oxidized)
[![Join the chat at https://gitter.im/oxidized/Lobby](https://badges.gitter.im/oxidized/Lobby.svg)](https://gitter.im/oxidized/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Oxidized is a network device configuration backup tool. It's a RANCID replacement!

It is light and extensible and supports over 130 operating system types.

Feature highlights:

* Automatically adds/removes threads to meet configured retrieval interval
* Restful API to a move node immediately to head-of-queue (GET/PUT /node/next/[NODE])
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
    * [Rocky Linux, Red Hat Enterprise Linux](#rocky-linux-red-hat-enterprise-linux)
    * [FreeBSD](#freebsd)
    * [Build from Git](#build-from-git)
    * [Docker & Podman](docs/Docker.md)
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
apt install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev libicu-dev zlib1g-dev g++ libyaml-dev
```

Finally, install Oxidized:

```shell
gem install oxidized
```

You can also install one or both of the optional gems. They are not required
to run Oxidized:
```shell
gem install oxidized-web    # Web interface and rest API
gem install oxidized-script # Script-based input/output extensions
```

### Rocky Linux, Red Hat Enterprise Linux
These instructions has been verified on Rocky Linux 9.3 and Fedora.

On Rocky Linux 9, you need to install/enable EPEL, CRB and Ruby 3.1:
```shell
dnf install epel-release
dnf config-manager --set-enabled crb
dnf module enable ruby:3.1
```

Then you need the required packages for oxidized:
```shell
dnf -y install ruby ruby-devel sqlite-devel openssl-devel pkgconf-pkg-config  cmake libssh-devel libicu-devel zlib-devel gcc-c++ libyaml-devel which
```

Finally, install Oxidized:

```shell
gem install oxidized
```

You can also install one or both of the optional gems. They are not required
to run Oxidized:
```shell
gem install oxidized-web    # Web interface and rest API
gem install oxidized-script # Script-based input/output extensions
```

### FreeBSD
These installation instructions have been tested on FreeBSD 14.2, but
oxidized itself has not been tested on it.

First install ruby and rubyXX-gems (Find out the name of the package with `pkg search gems`):
```shell
pkg instal ruby
pkg instal ruby32-gems
```

Then install the dependencies of oxidized an oxidized-web:
```shell
pkg install ruby ruby-gems git sqlite3 libssh2 cmake pkgconf gmake
pkg install libyaml icu   # Dependencies for oxidized-web
```

Finally, install Oxidized:

```shell
gem install oxidized
```

You can also install one or both of the optional gems. They are not required
to run Oxidized:
```shell
gem install oxidized-web    # Web interface and rest API
gem install oxidized-script # Script-based input/output extensions
```

Oxidized is also available via [FreeBSD ports](https://ports.freebsd.org/cgi/ports.cgi?query=oxidized):

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

### Running with Docker or Podman
See [docs/Docker.md](docs/Docker.md)

## Configuration

Oxidized configuration is in YAML format. Configuration files are subsequently sourced from `/etc/oxidized/config` then `~/.config/oxidized/config`. The hashes will be merged, this might be useful for storing source information in a system wide file and  user specific configuration in the home directory (to only include a staff specific username and password). Eg. if many users are using `oxs`, see [Oxidized::Script](https://github.com/ytti/oxidized-script).

It is recommended practice to run Oxidized using its own username.  This username can be added using standard command-line tools:

```shell
useradd -s /bin/bash -m oxidized
```

> It is recommended __not__ to run Oxidized as root. After creating a dedicated user, switch to the oxidized user using su oxidized to ensure that Oxidized is run under the correct user context.

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
