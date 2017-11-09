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
  * `nodes_done`: triggered after finished fetching all nodes.

## Hook type: exec
The `exec` hook type allows users to run an arbitrary shell command or a binary when triggered.

The command is executed on a separate child process either in synchronous or asynchronous fashion. Non-zero exit values cause errors to be logged. STDOUT and STDERR are currently not collected.

Command is executed with the following environment:
```
OX_EVENT
OX_NODE_NAME
OX_NODE_IP
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

Optionally you can disable snippets and post a formatted message, for instance linking to a commit in a git repo. Named parameters `%{node}`, `%{group}`, `%{model}` and `%{commitref}` are available.

``` yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "#network-changes"
    diff: false
    message: "%{node} %{group} %{model} updated https://git.intranet/network-changes/commit/%{commitref}"
```

Note the channel name must be in quotes.

## Hook type: xmppdiff

The `xmppdiff` hook posts config diffs to a [XMPP](https://en.wikipedia.org/wiki/XMPP) chatroom of your choice. It only triggers for `post_store` events.

You will need to manually install the `xmpp4r` gem on your system:

```
gem install xmpp4r
```

Configuration example:

``` yaml
hooks:
  xmpp:
    type: xmppdiff
    events: [post_store]
    jid: "user@server.tld/resource"
    password: "password"
    channel: "room@server.tld"
    nick: "nickname"
```

Note the channel name must be in quotes.
