# Pitch
 * automatically adds/removes threads to meet configured retrieval interval
 * restful API to move node immediately to head-of-queue (maybe trigger from snmp trap or syslog), to be serviced by next spawned thread (GET /nodes/next/$node)
 * restful API to reload list of nodes (GET /nodes/reload)

# Install
 early days, but try to run it and edit ~/.config/oxidized/config

# API
## Input
 * gets config from nodes
 * must implement 'connect', 'get'
 * 'ssh' and 'telnet' implemented

## Output
 * stores config
 * must implement 'update'
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
 * 'junos' and 'ios' implemented
