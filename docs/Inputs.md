# Inputs
## Index
* Configuration
  * [SSH](#ssh)
  * [SCP](#scp)
  * [FTP](#ftp)
  * telnet
  * http
  * tftp
  * exec
* [Debugging](#debugging)

## SSH
### Disabling SSH exec channels

Oxidized uses exec channels to make information extraction simpler, but there
are some situations where this doesn't work well, e.g. configuring devices. This
feature can be turned off by setting the `ssh_no_exec`
variable.

```yaml
vars:
  ssh_no_exec: true
```

### Disabling SSH keepalives

Oxidized SSH input makes use of SSH keepalives to prevent timeouts from slower
devices and to quickly tear down stale sessions in larger deployments. There
have been reports of SSH keepalives breaking compatibility with certain OS
types. They can be disabled using the `ssh_no_keepalive` variable on a per-node
basis (by specifying it in the source) or configured application-wide.

```yaml
vars:
  ssh_no_keepalive: true
```

### SSH Auth Methods

By default, Oxidized registers the following auth methods: `none`, `publickey` and `password`. However you can configure this globally, by groups, models or nodes.

```yaml
vars:
  auth_methods: [ "none", "publickey", "password", "keyboard-interactive" ]
```

### Public Key Authentication with SSH

Instead of password-based login, Oxidized can make use of key-based SSH
authentication.

You can tell Oxidized to use one or more private keys globally, or specify the
key to be used on a per-node basis. The latter can be done by mapping the
`ssh_keys` variable through the active source.

Global:

```yaml
vars:
  ssh_keys: "~/.ssh/id_rsa"
```

Per-Node:

```yaml
# ...
map:
  name: 0
  model: 1
vars_map:
  enable: 2
  ssh_keys: 3
# ...
```

If you are using a non-standard path, especially when copying the private key
via a secured channel, make sure that the permissions are set correctly:

```bash
foo@bar:~$ ls -la ~/.ssh/
total 20
drwx------ 2 oxidized oxidized 4096 Mar 13 17:03 .
drwx------ 5 oxidized oxidized 4096 Mar 13 21:40 ..
-r-------- 1 oxidized oxidized  103 Mar 13 17:03 authorized_keys
-rw------- 1 oxidized oxidized  399 Mar 13 17:02 id_ed25519
-rw-r--r-- 1 oxidized oxidized   94 Mar 13 17:02 id_ed25519.pub
```

Finally, multiple private keys can be specified as an array of file paths, such
as `["~/.ssh/id_rsa", "~/.ssh/id_another_rsa"]`.

### SSH Proxy Command

Oxidized can `ssh` through a proxy as well. To do so we just need to set
`ssh_proxy` variable with the proxy host information and optionally set the
`ssh_proxy_port` with the SSH port if it is not listening on port 22.

This can be provided on a per-node basis by mapping the proper fields from your
source.

An example for a `csv` input source that maps the 4th field as the `ssh_proxy`
value and the 5th field as `ssh_proxy_port`.

```yaml
# ...
map:
  name: 0
  model: 1
vars_map:
  enable: 2
  ssh_proxy: 3
  ssh_proxy_port: 4
# ...
```

### SSH enabling legacy algorithms

When connecting to older firmware over SSH, it is sometimes necessary to enable
legacy/disabled settings like KexAlgorithms, HostKeyAlgorithms, MAC or the
Encryption.

These settings can be provided on a per-node basis by mapping the ssh_kex,
ssh_host_key, ssh_hmac and the ssh_encryption fields from you source.

```yaml
# ...
map:
  name: 0
  model: 1
vars_map:
  enable: 2
  ssh_kex: 3
  ssh_host_key: 4
  ssh_hmac: 5
  ssh_encryption: 6
# ...
```

### Custom SSH port
Set the variable `ssh_port` to the desired value (default is 22).

### SSH Host key verification
With the configuration `secure', you can set the ssh key verification:
- `true`: strict host verification, looking up the known host files
- `false` (default): disable host verification, accept any ssh key

```
input:
  ssh:
    secure: true
```

## SCP
### SSH Host key verification (SCP)
Same as for [SSH host key verification](#ssh-host-key-verification)

```
input:
  scp:
    secure: true
```

### Custom SCP port
Set the variable `ssh_port` to the desired value (default is 22).

## FTP
### FTP Passive Mode

Oxidized uses ftp passive mode by default. Some devices require passive mode to
be disabled. To do so, we can set `input.ftp.passive` to false - this will make
use of FTP active mode.

```yaml
input:
  ftp:
    passive: false
```


## Debugging

In case a model plugin doesn't work correctly (ios, procurve, etc.), you can
enable live debugging of SSH/Telnet sessions. Just add a `debug` option
containing the value true to the `input` section. The log files will be created
depending on the parent directory of the logfile option.

The following example will log an active ssh/telnet session
`/home/oxidized/.config/oxidized/log/<IP-Address>-<PROTOCOL>`. The file will be
truncated on each consecutive ssh/telnet session, so you need to put a `tailf`
or `tail -f` on that file!

```yaml
log: /home/oxidized/.config/oxidized/log

# ...

input:
  default: ssh, telnet
  debug: true
  ssh:
    secure: false
  http:
    ssl_verify: true
```