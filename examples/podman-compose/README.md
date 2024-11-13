# Running Oxidized with podman-compose
This example demonstrates running Oxidized within an OCI container using
podman-compose. It’s actively used in Oxidized development to validate the
container’s functionality and to simulate potential issues.

While this example uses podman and podman-compose, it should also be compatible
with docker, as podman supports docker’s CLI.

To make this example work seamlessly, a simulated network device is included.
The asternos model is used here for simplicity, as it requires minimal commands
to implement. The simulated output doesn’t replicate real device responses but
provides changing lines over time to test Oxidized’s functionality.


The example also provides a Git server to test the interaction with it.

# Run the example
> :warning: the example builds local containers and will require at least 2 GB
> of disk space along with some CPU and time during the first run.

To start the example, simply run `make start`. Ensure you have installed the
necessary [dependencies](#dependencies) before.

To stop, press `CTRL-C` or run `make stop` in a separate shell. If you exit
with `CTRL-C`, make sure to run `make stop` afterward to properly clean up the
environment.

## Running Environment
This example of oxidized with podman-compose is running on Debian
Bookworm (Version 12). It should work with few adaptations on any Linux
box running podman, and maybe also with docker.

## Dependencies
To get started, install the required packages on your Debian system:
```shell
sudo apt install podman containers-storage podman-compose make
```

Ensure Podman is using the overlay driver for image storage.
Without this driver, Podman may save every container layer separately rather
than only the changes, which can quickly consume disk space.

This issue can occur if podman was run before installing the
`container-storage`  package.

```shell
podman info | grep graphDriverName
```

You should get this reply
```shell
  graphDriverName: overlay
```

If not, the quick way I found to solve it is to delete `~/.local/share/containers/`.
Beware - this will delete **all** your containers!

## Adapting to your needs
Feel free to customize this setup as you wish! You may want to edit
`docker-compose.yml` to remove any containers simulating specific components.

## Use your own oxidized configuration in the git repository
When developing oxidized or testing the container, you may want to use a custom
configuration. This can be done by saving it under `oxidized-config/config.local`

`make start-local` will recognize the local configuration and copy it to
`oxidized-config/config` before starting the container.

You should stop the container with `make stop-local` in order to restore the
original configuration from the git repository.

In the folder `oxidized-config/, you will also find some example configs,
for example `config_csv-gitserver`. To use them, just copy the file to `config`.

## Git server public keys
To enable Oxidized to access the Git server, you'll need to retrieve the
servers' public SSH keys and store them under `oxidized-ssh/known_hosts`.
Without this, you will encounter the following error:

```
ERROR -- : Hook push_to_remote (#<GithubRepo:0x00007f4cff47d918>) failed (#<Rugged::SshError: invalid or unknown remote ssh hostkey>) for event :post_store
```

While the container environment is running (`make start`), open a separate shell
and run:
```
make gitserver-getkey
```

You do not need to restart the container environment; Oxidized will
automatically use the key the next time it pushes to the remote Git repository.



