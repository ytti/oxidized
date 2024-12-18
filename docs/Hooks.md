# Hooks

You can define an arbitrary number of hooks that subscribe to different events. The hook system is modular and different kind of hook types can be enabled.

1. [Events](#events)
2. Hook types
 * [exec](#hook-type-exec)
 * [githubrepo](#hook-type-githubrepo)
 * [awssns](#hook-type-awssns)
 * [slackdiff](#hook-type-slackdiff)
 * [ciscosparkdiff](#ciscosparkdiff)
 * [xmppdiff](#hook-type-xmppdiff)

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
OX_ERR_TYPE
OX_ERR_REASON
```

Exec hook recognizes the following configuration keys:

* `timeout`: hard timeout (in seconds) for the command execution. SIGTERM will be sent to the child process after the timeout has elapsed. Default: `60`
* `async`: Execute the command in an asynchronous fashion. The main thread by default will wait for the hook command execution to complete. Set this to `true` for long running commands so node configuration pulls are not blocked. Default: `false`
* `cmd`: command to run.

### Exec Hook configuration example

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

### Exec Hook configuration example to send mail

To send mail you need the package `msmtp` (It is pre-installed with the docker container) 

You then need to update the `~/.msmtprc` file to contain your SMTP credentials like this:

*Note: In the docker container the file is in /home/oxidized/.config/oxidized/.msmtprc so you can create the file if it doesn't exist in your oxidized config folder.*

```cfg
# Default settings
defaults
auth    on
tls    on
# Outlook SMTP
account    mainaccount
host       smtp.office365.com
port       587
from       user@domain.com
user       user@domain.com
password   edit-password

account default : mainaccount
```

For non docker users this file should have the 600 permission, using: `chmod 600 .msmtprc` and the owner of the file should be the owner of oxidized `chown oxidized:oxidized .msmtprc`

Then, you can configure Hooks to send mail like this:

```yaml
hooks:
  send_mail_hook:
    type: exec
    events: [node_fail]
    cmd: '/usr/bin/echo -e "Subject: [Oxidized] Error on node $OX_NODE_NAME \n\nThe device $OX_NODE_NAME has not been backed-up, reason: \n\n$OX_EVENT: $OX_ERR_REASON" | msmtp destination@domain.com'
```

## Hook type: githubrepo

Note: You must not use the same name as any local repo configured under output. Make sure your 'git' output has a unique name that does not match your remote_repo.

The `githubrepo` hook executes a `git push` to a configured `remote_repo` when the specified event is triggered.

Several authentication methods are supported:

* Provide a `password` for username + password authentication
* Provide both a `publickey` and a `privatekey` for ssh key-based authentication
* Provide only a `privatekey` (public key filename is assumed to be `privatekey` + "`.pub`"
* Don't provide any credentials for ssh-agent authentication

The username will be set to the relevant part of the `remote_repo` URI, with a fallback to `git`. It is also possible to provide one by setting the `username` configuration key.

For ssh key-based authentication, it is possible to set the environment variable `OXIDIZED_SSH_PASSPHRASE` to a passphrase if the private key requires it.

`githubrepo` hook recognizes the following configuration keys:

* `remote_repo`: the remote repository to be pushed to.
* `username`: username for repository auth.
* `password`: password for repository auth.
* `publickey`: public key file path for repository auth. (optional)
* `privatekey`: private key file path for repository auth.
  * NOTE: this key needs to be in the legacy PEM format, not the newer OpenSSL format [#1877](https://github.com/ytti/oxidized/issues/1877), [#2324](https://github.com/ytti/oxidized/issues/2324)
    * To convert a key beginning with `BEGIN OPENSSH PRIVATE KEY` to the legacy PEM format, run this command:
      `ssh-keygen -p -m PEM -f $MY_KEY_HERE`

When using groups, `remote_repo` must be a dictionary of groups that the hook should apply to. If a group is missing from the dictionary, no action will be taken.

The dictionary entry can either be a url alone:

```yaml
hooks:
  push_to_remote:
    remote_repo:
      routers: git@git.intranet:oxidized/routers.git
      switches: git@git.intranet:oxidized/switches.git
      firewalls: git@git.intranet:oxidized/firewalls.git
```

... or it can be a dictionary with `url` and `privatekey` specified:

```yaml
hooks:
  push_to_remote:
    remote_repo:
      routers:
        url: git@git.intranet:oxidized/routers.git
        privatekey: /root/.ssh/id_rsa_routers
      switches:
        url: git@git.intranet:oxidized/switches.git
        privatekey: /root/.ssh/id_rsa_switches
      firewalls:
        url: git@git.intranet:oxidized/firewalls.git
        privatekey: /root/.ssh/id_rsa_firewalls
```

Both forms can be mixed and matched.

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

### Custom branch name
Githubrepo will use the branch name used in the
[git output](Outputs.md#output-git) as a remote branch name. When creating the
git repository for the first time, Oxidized uses the default branch name
configured in git with `git config --global init.defaultBranch <Name>`. The
default is `master`.

If you need to rename the branch name after Oxidized has created it, you may do
it manually. Be aware that you may break things. Make backups and do not
complain if something goes wrong!

1. Stop oxidized (no one should access the git repository while doing the
following steps)
2. Make a backup of your oxidized data, especially the git repository
3. Change directory to your oxidized git repository (as configured in oxidized
configuration file)
4. Inspect the current branches with `git branch -avv`
5. Rename the default branch with `git branch -m <NewName>`
6. Remove the reference to the old remote branch  with
   `git branch -r -d origin/<OldName>`
6. Inspect the change with `git branch -avv`
7. Restart oxidized - you're done!

Note that you will also have to clean your remote git repository.

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

The `slackdiff` hook posts colorized config diffs to a [Slack](https://www.slack.com) channel of your choice. It only triggers for `post_store` events.

You will need to manually install the `slack-ruby-client` gem on your system:

```shell
gem install slack-ruby-client
```

### slackdiff hook configuration example

> Please note that the channel needs to be your Slack channel ID.

```yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "CHANNEL_ID"
```

The token parameter is a Slack API token that can be generated following [this tutorial](https://api.slack.com/tutorials/tracks/getting-a-token).  Until Slack stops supporting them, legacy tokens can also be used.

Optionally you can disable snippets and post a formatted message, for instance linking to a commit in a git repo. Named parameters `%{node}`, `%{group}`, `%{model}` and `%{commitref}` are available.

```yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "CHANNEL_ID"
    diff: false
    message: "%{node} %{group} %{model} updated https://git.intranet/network-changes/commit/%{commitref}"
```

A proxy can optionally be specified if needed to reach the Slack API endpoint.

```yaml
hooks:
  slack:
    type: slackdiff
    events: [post_store]
    token: SLACK_BOT_TOKEN
    channel: "#CHANNEL_ID"
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
