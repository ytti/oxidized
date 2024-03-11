This is `~/.ssh/` of the user oxidized inside the oxidized container.

## What you need here for the hook githubrepo
You can store the SSH key needed to access a remote Git repository here. Here is
an example how to generate this key.
```shell
ssh-keygen -q -t ed25519 -C "Oxidized Push Key@`hostname`" -N "YOURPASSPHRASE" -m PEM -f oxidized-key
```

You also need to store the public keys of the remote git server in known_hosts. If you do not,
oxidized will refuse to push to the remote Git with the error `#<Rugged::SshError: invalid or unknown remote ssh hostkey>`, see Issue #2753.
```shell
ssh-keyscan git-server.example.com > known_hosts
```
