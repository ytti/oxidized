# APC AOS Configuration

Currently, the configuration of APC Network Management Cards can be downloaded with FTP only.

A download of the configuration with SCP is [work in progress](https://github.com/ytti/oxidized/issues/1802).
As the APC has an unusual behavior (the connection is closed without an exit-status), this has to be
[fixed](https://github.com/net-ssh/net-scp/pull/71) upstream in [Net::SCP](https://github.com/net-ssh/net-scp).
As soon as there is a release of Net::SCP supporting the behavior of APC OS, we will activate SCP in oxidized.

## Can I collect more information than just the configuration?
APC OS does not have the ability to show the config.ini within an SSH-session. As oxidized can only get the
configuration with one input type at a time, it is not possible to fetch config.ini via FTP/SCP and get the output of
some commands via SSH at the same time.

A ticket has been opened with APC support in order to support "cat config.ini" within an SSH-session, but
the chances it will be supported at some time are not very good, and older versions will still not support it.

## How do I activate FTP input?
In order to download the configuration with FTP (and in the future with SCP), you have to activate it as an
input in the oxidized configuration. If you do not activate the input, oxidized will fail for the node with
a rather unspecific error (`WARN -- : /apc status fail, retry attempt 1`).

The configuration can be done either globally or only for the model apc_aos.

The global configuration would look like this. Note that Oxidized will try every input type in the given order
until it succeeds, or it will report a failure.
```yaml
input:
  default: ssh, ftp, scp
```

Configuration for activating the FTP input for apc_aos only:
```yaml
input:
  default: ssh
models:
  apc_aos:
    input: ftp
```

You can also set specific username and password for apc_aos only:
```yaml
username: default-user
password: default-password
input:
  default: ssh
models:
  apc_aos:
    username: apc-user
    password: apc-password
    input: ftp
```
