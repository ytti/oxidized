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

`ssh_proxy` must be `[user@]host`, where `host` is a hostname (RFC 1123), an
IPv4 or an IPv6 address, and `ssh_proxy_port` must be an integer. Other values
are rejected and the node fails.

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

### SSH Diffie-Hellman group size
net-ssh >= 8.0 requires Diffie-Hellman group exchange groups of at least 2048
bits. Some old devices only offer 1024-bit groups and fail to connect. Set the
variable `ssh_minimum_dh_bits` to accept smaller groups for these devices:

```yaml
vars:
  ssh_minimum_dh_bits: 1024
```

Or only for one model:

```yaml
models:
  ios:
    vars:
      ssh_minimum_dh_bits: 1024
```


### SSH public key algorithms
Since net-ssh 8.1, each RSA key is offered only once, with a single signature
algorithm, as OpenSSH does:
- If the device announces the algorithms it accepts (RFC 8308
  `server-sig-algs`), Net::SSH uses the first one of `rsa-sha2-512`,
  `rsa-sha2-256` and `ssh-rsa` that the device lists.
- Otherwise, the key is offered as `ssh-rsa`.

There is no fallback to another algorithm when the device rejects the
signature. Some devices announce `rsa-sha2-*` but only accept `ssh-rsa`, or
drop the connection on a `rsa-sha2-*` signature, e.g. Huawei SmartAX MA5683T
(#2875). Public key authentication with RSA keys then fails.

Set the variable `ssh_pubkey_algorithms` to choose the preferred algorithms,
in order, for these devices:

```yaml
models:
  smartax:
    vars:
      ssh_pubkey_algorithms: ssh-rsa
```

The listed algorithms are tried first, the other supported algorithms are
appended, so in practice this only changes the choice for RSA keys. The
OpenSSH prefixes `+`, `-` and `^` are supported, e.g. `-ssh-rsa` removes
`ssh-rsa`. Unsupported values are ignored.

### Custom SSH port
Set the variable `ssh_port` to the desired value (default is 22).

### OpenSSH configuration files
Net::SSH reads the OpenSSH configuration of the user running Oxidized:
`~/.ssh/config`, `/etc/ssh_config` and `/etc/ssh/ssh_config`, including their
`Include` files. `Host` blocks are matched against the IP address of the node.

Options set by Oxidized take precedence over the configuration files: the
`ssh_*` variables, `auth_methods`, the port, the timeout, keepalives and host
key verification.

Since net-ssh 8.0, the files are parsed more like OpenSSH:
- `KexAlgorithms` and `PubkeyAcceptedAlgorithms` are read, in addition to
  `Ciphers`, `MACs` and `HostKeyAlgorithms`.
- Algorithm lists support the `+`, `-` and `^` prefixes. As Oxidized appends all
  supported algorithms, a plain list only changes the preference order, but
  `-` removes algorithms, which may break old devices.
- `Match` supports `all`, `Host`, `OriginalHost`, `User` (the username of the
  node) and `LocalUser`. Blocks with other conditions (`exec`, `canonical`, ...)
  are skipped and a warning is printed to stderr.

If a device fails to connect after a system or net-ssh upgrade, check these
files, including system-wide crypto policies (e.g. on RHEL or Fedora).

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

## HTTP
### Supported HTTP Methods

The HTTP input supports the following HTTP methods:
- `:get`  - for GET requests
- `:post` - for POST requests
- `:delete` - for DELETE requests

These methods are used internally by models that require HTTP-based 
configuration retrieval. Models can use `get_http()`, `post_http()` and
`delete_http()` methods provided by the HTTP input.

Example usage in a model:

```ruby
cfg :http do
  post_response   = post_http('/some/path', payload, 'Some-Extra-Header' => 'value')
  get_response    = get_http('/some/path')
  delete_response = delete_http('/some/path')
end
```

HTTP input can be enabled by adding this block to the configuration file:

```yaml
input:
  http:
    scheme: https
    ssl_verify: true
    timeout: 30
```

## Debugging
In case a model plugin doesn't work correctly (ios, procurve, etc.), you can
enable live debugging of SSH and Telnet sessions with the `debug` option of
the `input` section.

Starting with version 0.37.0, `debug` can take different values:
- `text`: log input and output to a text file (ssh, telnet)
- `yaml`: produce a yaml simulation file (ssh)
- `library`: activate debug logging of the underlying library
- a combination of the options above (`text, yaml`)
- `true`; activate all debugging options (Only option for versions prior 0.37.0)

The log files will be created in `~/.config/oxidized/logs/` (or `$OXIDIZED_LOGS/logs/`).

The following example will log an active ssh/telnet session to
`~/.config/oxidized/logs/<IP-Address>-<PROTOCOL>-<timestamp>.txt` and for ssh
`~/.config/oxidized/logs/<IP-Address>-<PROTOCOL>-<timestamp>.yaml`. A new file
is created for each session.

```yaml
input:
  default: ssh, telnet
  debug: yaml, text
  ssh:
    secure: false
  http:
    ssl_verify: true
```