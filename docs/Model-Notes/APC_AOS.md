# APC AOS Configuration

The configuration of APC Network Management Cards can be downloaded using FTP
and SCP.

To download with SCP, you need a
[patch](https://github.com/net-ssh/net-scp/pull/71) to
[Net::SCP](https://github.com/net-ssh/net-scp, which has been included
upstream, but there is currently no new release of Net::SCP and its authors are
unresponsive.

To temporarily solve this,
[@robertcheramy forked Net::SCP](https://github.com/robertcheramy/net-scp). You
can build or download the gem there. This gem is already included in the
oxidized container image (in the release coming after 0.31.0).


## Can I collect more information than just the configuration?
APC OS does not have the ability to show the config.ini within an SSH-session.
As oxidized can only get the configuration with one input type at a time, it is
not possible to fetch config.ini via FTP/SCP and get the output of
some commands via SSH at the same time. Feature request #3334 has been opened
to support multiple inputs in oxidized.

A ticket has been opened with APC support in order to enable "cat config.ini"
within an SSH-session, but APC is not willing to support this.


## How do I activate FTP/SCP input?
In order to download the configuration with FTP or SCP, you have to activate it
as an input in the oxidized configuration. If you do not activate the input,
oxidized will fail for the node with a
[rather unspecific error](https://github.com/ytti/oxidized/issues/3346)
(`WARN -- : /apc status fail, retry attempt 1`).

The configuration can be done either globally or only for the model apc_aos.

The global configuration would look like this. Note that Oxidized will try every
input type in the given order until it succeeds, or it will report a failure.
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
