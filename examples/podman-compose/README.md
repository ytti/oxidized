# Running oxidized with podman-compose
This is an example of Oxidized running within an OCI container, provided by
podman and podman-compose.

In order to have the example work out of the box, a network device is simulated.
The model asternos has been chosen because there were not too many commands to
implement.

To run the example, just run `make start`. You should be sure to have installed the
[dependencies](#dependencies) before.

To exit, press `CTRL-C` or run `make stop` in a separate shell. If you exit
with `CTRL-C`, make sure to run `make stop` after it, in order to clean up the
running environment.

## Running Environment
This example of oxidized with podman-compose has been run on Debian
Bookworm (Version 12), but should work with few adaptations on any Linux
box running podman, and maybe also with docker.

## Dependencies
You need to install some packages on your debian system:
```shell
sudo apt install podman containers-storage podman-compose make
```

You also want to make sure that podman uses the overlay driver for storing its images.
If not, it will save every layer of the container to disk (and not only the delta),
so it will fill your disk very fast.

This happens if you run podman without having installed the package `container-storage`
before.

```shell
podman info | grep graphDriverName
```

You should get this reply
```shell
  graphDriverName: overlay
```

If not, the quick way I found to solve it is to delete `~/.local/share/containers/`.
Beware - this will delete **all** your containers!

## I want to adapt this to my needs
Feel free and have fun. You probably want to edit docker-compose.yml in order to remove the
simulated model.

## Use your own oxidized configuration within the git repository
When developing oxidized and testing the container, you may want to use your
own configuration. This can be done by saving it under `oxidized-config/config.local`

`make start-local` will recognize the local configuration and copy it to
`oxidized-config/config` before starting the container.

You shoud stop the container with `make stop-local` in order to restore the original
configuration from git.
