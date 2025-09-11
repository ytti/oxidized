# Troubleshooting
## Table of contents
1. [Connects but no/partial configuration collected](#oxidized-connects-to-a-supported-device-but-no-or-partial-configuration-is-collected)
2. [No push to remote git repository](#oxidized-does-not-push-to-a-remote-git-repository-hook-githubrepo)
3. [Git performance issues with large device counts](#git-performance-issues-with-large-device-counts)
4. [Oxidized ignores the changes I made to its git repository](#oxidized-ignores-the-changes-i-made-to-its-git-repository)

## Oxidized connects to a supported device but no (or partial) configuration is collected

A common reason for configuration collection to fail after successful authentication is prompt mismatches. The symptoms typically fall into one of two categories:

* Oxidized successfully logs into the device, then reports a timeout without collecting configuration. This can be caused by an unmatched prompt.
* Only partial output is collected and collection stops abruptly. This can be caused by overly greedy prompt being matched against non-prompt output.

*Troubleshooting an unmatched prompt:*

Log in manually into the device. Use the same username and password or key configured for Oxidized. Observe the prompt returned by the device.

```text
Logging into this device is dangerous! Do so at your own risk.

Username: superuser
Password: *********

Welcome to the advanced nuclear launchinator 5A-X20. Proceed with caution.

SEKRET-5A-X20#
```

Review the relevant device model file and identify the defined prompt. You can
find the device models in the `lib/oxidized/model` subdirectory of the
repository. For example, the Cisco IOS model, `ios.rb` may use the following
prompt:

```text
  prompt /^([\w.@()-]+[#>]\s?)$/
```

Use IRB to verify if the prompt you've observed would match:

An example of a successful match:

```shell
# irb
irb(main):001:0> 'SEKRET-5A-X20#'.match /^([\w.@()-]+[#>]\s?)$/
=> #<MatchData "SEKRET-5A-X20#" 1:"SEKRET-5A-X20#">
irb(main):002:0>
```

An example of an unsuccessful match, for the prompt `$EKRET-5A-X20#` ($ used instead of capital S at the beginning of the prompt):

```shell
irb(main):002:0> '$EKRET-5A-X20#'.match /^([\w.@()-]+[#>]\s?)$/
=> nil
```

The prompt can then be adapted and re-tested, for example, by allowing the $ character as part of the prompt via `/^([\$\w.@()-]+[#>]\s?)$/`

```shell
irb(main):003:0> '$EKRET-5A-X20#'.match /^([\$\w.@()-]+[#>]\s?)$/
=> #<MatchData "$EKRET-5A-X20#" 1:"$EKRET-5A-X20#">
```

The new prompt now matches. You can copy the current model into the `~/.config/oxidized/model/` directory (keeping the original file name), and modify the prompt within the model file. After restarting Oxidized, the adapted model will be used.

*Troubleshooting an overly greedy prompt:*

Log in manually into the device. Use the same username and password or key configured for Oxidized. Execute the last command (which may be the first command to run) from which partial output is collected.

Compare the output to the partial output collected by Oxidized, focusing on the the difference that has been truncated. You can evaluate if this output could have matched the prompt regexp unexpectedly with IRB in a manner similar to the outlined in the previous section.

Adapt the prompt regexp to be more conservative if necessary in a local model override file.

*We encourage you to submit a PR for any prompt issues you encounter.*

## Oxidized does not push to a remote Git repository (hook githubrepo)
See Issue #2753

You need to store the public SSH keys of the remote Git server to the ~/.ssh/known_hosts
of the user running oxidized.

This can be done with
```shell
ssh-keyscan gitserver.git.com >> ~/.ssh/known_hosts
```

If you are running oxidized in a container, you need to map /home/oxidized/.ssh in the
container to a local repository and save the known_hosts in the local repository. You can
find an example how to do this under [examples/podman-compose](/examples/podman-compose/)

## Oxidized ignores the changes I made to its git repository
First of all: you shouldn't manipulate the git repository of oxidized. Don't
create it, don't modify it, leave it alone. You can break things. You have
been warned.

In some situations, you may need to make changes to the git repository of
oxidized. Stop oxidized, make backups, and be sure you know exactly what you
are doing. You have been warned.

If you simply clone the git repository, make changes and push them, oxidized
will ignore these modifications. This is because oxidized caches the HEAD tree
in the index and `git push` does not update the index because the repository is
a bare repo and not a working directory repository.

So, you have to update the index manually. For this, go into oxidized repo, and
run `git ls-tree -r HEAD | git update-index --index-info`. While you're at it,
consider running `git gc`, as oxidized cannot garbage collect the repo (this
is not supported in [Rugged](https://github.com/libgit2/rugged)).
