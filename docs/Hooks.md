# Hooks

You can define an arbitrary number of hooks that subscribe to different events. The hook system is modular and different kind of hook types can be enabled.

## Configuration

Following configuration keys need to be defined for all hooks:

* `events`: which events to subscribe. Needs to be an array. See below for the list of available events.
* `type`: what hook class to use. See below for the list of available hook types.

## Events

* `node_success`: triggered when configuration is successfully pulled from a node and right before storing the configuration.
* `node_fail`: triggered after `retries` amount of failed node pulls.
* `post_store`: triggered after node configuration is stored (this is executed only when the configuration has changed).
* `nodes_done`: triggered after finished fetching all nodes.

## Hook type: exec

The `exec` hook type allows users to run an arbitrary shell command or a binary when triggered.

The command is executed on a separate child process either in synchronous or asynchronous fashion. Non-zero exit values cause errors to be logged. STDOUT and STDERR are currently not collected.

Command is executed with the following environment:

```text
OX_EVENT
OX_NODE_NAME
OX_NODE_IP
OX_NODE_FROM
OX_NODE_MSG
OX_NODE_GROUP
OX_NODE_MODEL
OX_JOB_STATUS
OX_JOB_TIME
OX_REPO_COMMITREF
OX_REPO_NAME
```

Exec hook recognizes the following configuration keys:

* `timeout`: hard timeout (in seconds) for the command execution. SIGTERM will be sent to the child process after the timeout has elapsed. Default: `60`
* `async`: Execute the command in an asynchronous fashion. The main thread by default will wait for the hook command execution to complete. Set this to `true` for long running commands so node configuration pulls are not blocked. Default: `false`
* `cmd`: command to run.

### exec hook configuration example

```yaml
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

## Hook type: githubrepo

The `githubrepo` hook executes a `git push` to a configured `remote_repo` when the specified event is triggered.

Several authentication methods are supported:

* Provide a `password` for username + password authentication
* Provide both a `publickey` and a `privatekey` for ssh key-based authentication
* Don't provide any credentials for ssh-agent authentication

The username will be set to the relevant part of the `remote_repo` URI, with a fallback to `git`. It is also possible to provide one by setting the `username` configuration key.

For ssh key-based authentication, it is possible to set the environment variable `OXIDIZED_SSH_PASSPHRASE` to a passphrase if the private key requires it.

`githubrepo` hook recognizes the following configuration keys:

* `remote_repo`: the remote repository to be pushed to.
* `username`: username for repository auth.
* `password`: password for repository auth.
* `publickey`: public key file path for repository auth.
* `privatekey`: private key file path for repository auth.

When using groups, each group must have a unique entry in the `remote_repo` config.

```yaml
hooks:
  push_to_remote:
    remote_repo:
      routers: git@git.intranet:oxidized/routers.git
      switches: git@git.intranet:oxidized/switches.git
      firewalls: git@git.intranet:oxidized/firewalls.git
```

### githubrepo hook configuration example

Authenticate with a username and a password without groups in use:

```yaml
hooks:
  push_to_remote:
    type: githubrepo
    events: [post_store]
    remote_repo: git@git.intranet:oxidized/test.git
    username: user
    password: pass
```

Authenticate with the username `git` and an ssh key:

```yaml
hooks:
  push_to_remote:
    type: githubrepo
    events: [post_store]
    remote_repo: git@git.intranet:oxidized/test.git
    publickey: /root/.ssh/id_rsa.pub
    privatekey: /root/.ssh/id_rsa
```

## Hook type: awssns

The `awssns` hook publishes messages to AWS SNS topics. This allows you to notify other systems of device configuration changes, for example a config orchestration pipeline. Multiple services can subscribe to the same AWS topic.

Fields sent in the message:

* `event`: Event type (e.g. `node_success`)
* `group`: Group name
* `model`: Model name (e.g. `eos`)
* `node`: Device hostname

The AWS SNS hook requires the following configuration keys:

* `region`: AWS Region name
* `topic_arn`: ASN Topic reference

### awssns hook configuration example

```yaml
hooks:
  hook_script:
    type: awssns
    events: [node_fail,node_success,post_store]
    region: us-east-1
    topic_arn: arn:aws:sns:us-east-1:1234567:oxidized-test-backup_events
```

Your AWS credentials should be stored in `~/.aws/credentials`.

## Hook type: slackdiff

The `slackdiff` hook posts colorized config diffs to a [Slack](http://www.slack.com) channel of your choice. It only triggers for `post_store` events.

You will need to manually install the `slack-api` gem on your system:

```shell
gem install slack-api
```

### slackdiff hook configuration example

```yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "#network-changes"
```

The token parameter is a "legacy token" and is generated [Here](https://api.slack.com/custom-integrations/legacy-tokens).

Optionally you can disable snippets and post a formatted message, for instance linking to a commit in a git repo. Named parameters `%{node}`, `%{group}`, `%{model}` and `%{commitref}` are available.

```yaml
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

A proxy can optionally be specified if needed to reach the Slack API endpoint.

```yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "#network-changes"
    proxy: http://myproxy:8080
```

## Hook type: ciscosparkdiff

The `ciscosparkdiff` hook posts config diffs to a [Cisco Spark](https://www.ciscospark.com/) space of your choice. It only triggers for `post_store` events.

You will need to manually install the `cisco_spark` gem on your system (see [cisco_spark-ruby](https://github.com/NGMarmaduke/cisco_spark-ruby)) and generate either a [Bot or OAUTH access key](https://developer.ciscospark.com/apps.html), and retrieve the [Spark Space ID](https://developer.ciscospark.com/endpoint-rooms-get.html)

```shell
gem install cisco_spark
```

### ciscosparkdiff hook configuration example

```yaml
hooks:
  ciscospark:
    type: ciscosparkdiff
    events: [post_store]
    accesskey: SPARK_BOT_API_OR_OAUTH_KEY
    space: SPARK_SPACE_ID
    diff: true
```

Optionally you can disable snippets and post a formatted message, for instance linking to a commit in a git repo. Named parameters `%{node}`, `%{group}`, `%{model}` and `%{commitref}` are available.

```yaml
hooks:
  ciscospark:
    type: ciscosparkdiff
    events: [post_store]
    accesskey: SPARK_BOT_API_OR_OAUTH_KEY
    space: SPARK_SPACE_ID
    diff: false
    message: "%{node} %{group} %{model} updated https://git.intranet/network-changes/commit/%{commitref}"
```

Note the space and access tokens must be in quotes.

A proxy can optionally be specified if needed to reach the Spark API endpoint.

```yaml
hooks:
  ciscospark:
    type: ciscosparkdiff
    events: [post_store]
    accesskey: SPARK_BOT_API_OR_OAUTH_KEY
    space: SPARK_SPACE_ID
    diff: true
    proxy: http://myproxy:8080
```

## Hook type: xmppdiff

The `xmppdiff` hook posts config diffs to a [XMPP](https://en.wikipedia.org/wiki/XMPP) chatroom of your choice. It only triggers for `post_store` events.

You will need to manually install the `xmpp4r` gem on your system:

```shell
gem install xmpp4r
```

### xmppdiff hook configuration example

```yaml
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
