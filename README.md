# Pitch
 * automatically adds/removes threads to meet configured retrieval interval
 * restful API to move node immediately to head-of-queue 
   * syslog udp+file example to catch config changg event (ios/junos) and trigger config fetch
   * will signal ios/junos user who made change, which output module can (git does) use
   * 'git blame' will show for each line who and when the change was made
 * restful API to reload list of nodes (GET /nodes/reload)

# Install
 * early days, but try:
   1. apt-get install libsqlite3-dev
   2. gem install oxidized
   3. oxidized
   4. vi ~/.config/oxidized
   5. (maybe point to your rancid/router.db or copy it there)
   6. oxidized

# API
## Input
 * gets config from nodes
 * must implement 'connect', 'get', 'cmd'
 * 'ssh' and 'telnet' implemented

## Output
 * stores config
 * must implement 'store'
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
 * 'junos', 'ios', 'ironware' and 'powerconnect'
