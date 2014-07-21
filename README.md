# Pitch
 * automatically adds/removes threads to meet configured retrieval interval
 * restful API to move node immediately to head-of-queue (GET/POST /node/next/[NODE])
   * syslog udp+file example to catch config change event (ios/junos) and trigger config fetch
   * will signal ios/junos user who made change, which output module can (git does) use (via POST)
   * 'git blame' will show for each line who and when the change was made
 * restful API to reload list of nodes (GET /reload)
 * restful API to fetch configurations (/node/fetch/[NODE] or /node/fetch/group/[NODE])
 * restful API to show list of nodes (GET /nodes)

# Install
 * early days, but try:
   1. apt-get install ruby ruby-dev libsqlite3-dev libssl-dev
   2. gem install oxidized
   3. gem install oxidized-script oxidized-web # if you don't install oxidized-web, make sure you remove "rest" from your config
   4. oxidized
   5. vi ~/.config/oxidized/config
   6. (maybe point to your rancid/router.db or copy it there)
   7. oxidized

# API
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

## Media
 * TREX 2014 presentation - http://youtu.be/kBQ_CTUuqeU#t=3h

## Cookbook

### Configuration I use in one environment
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

### Configuration you end up after first run
If you don't configure output and source, it'll further fill them with example
configs for your chosen output/source in subsequent runs
```
---
username: username
password: password
model: junos
interval: 3600
log: "/home/fisakytt/.config/oxidized/log"
debug: false
threads: 30
timeout: 30
prompt: !ruby/regexp /^([\w.@-]+[#>]\s?)$/
rest: 127.0.0.1:8888
vars: {}
input:
  default: ssh, telnet
  ssh:
    secure: false
output:
  default: git
source:
  default: csv
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
    repo: "/home/fisakytt/.config/oxidized/oxidized.git"
source:
  default: csv
  csv:
    file: "/home/fisakytt/.config/oxidized/router.db"
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
