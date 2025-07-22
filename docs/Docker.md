# Running oxidized within an OCI container (docker, podman...)

## Docker image
The official Docker image is automatically built and pushed to hub.docker.com
as [oxidized/oxidized](https://hub.docker.com/r/oxidized/oxidized/) with a
[GitHub CI](/.github/workflows/publishdocker.yml).

There are three different types of tags:
- Each commit to the master branch will be published with the tag
  `master-(git sha oid)`
- Each release will be published with the version as a tag
- Latest is the latest release, either from a commit or a release tag

Currently, Docker Hub automatically builds the master branch for linux/amd64 and
linux/arm64 platforms as
[oxidized/oxidized](https://hub.docker.com/r/oxidized/oxidized/). You can make
use of this container or build your own.

## Choose a container running environment
There are many options to run containers. Two main options are
[docker](https://www.docker.com/) and [podman](https://podman.io/). A main
difference is that docker requires root rights to run, and podman can be run
by a local user. Both work with oxidized, so the choice is up to you.

Oxidized has also been reported to work with
[Portainer](https://www.portainer.io/).

## File rights in the container userspace and host userspace
As oxidized runs under the user "oxidized" (UID: 30000) in the container
userspace, docker and podman will map this UID in the shared volumes, producing
weird UIDs in the host userspace.

### docker
When docker runs the container as root, the mapping to the UIDs in the host
userspace will be the same as in the container, so the files produced by the
oxidized user in the container will have UID 30000 in the host.

If you map a volume between the host and the container and need it to be
accessed by the oxidized user, you need to fix the UIDs:
```
sudo chown 30000:30000 ~/oxidized-config
```

### podman
When podman is run as a user, the mapping of UIDs between the container and the
linux host will depend on your UID on the host.

If you map a volume between the host and the container and need it to be
accessed by the oxidized user, you need to fix the UIDs:

```
podman unshare chown 30000:30000 ~/oxidized-config
```

If you need to access the files from the linux host, you can do this by
prefixing `podman unshare` to your shell commands.

## Build you own container image
To build your own container image, clone the git repository:

```shell
git clone https://github.com/ytti/oxidized
```

Then, build the container locally:

```shell
sudo docker build -q -t oxidized/oxidized:latest oxidized/
```

- `-q` stands for quiet; remove it if you want to see the build process.
- `-t oxidized/oxidized:latest` tags the image as `oxidized/oxidized:latest`

You can also build with podman:
```
podman build -t oxidized:latest oxidized/
```

Within the oxidized repository, using `rake build_container` will automatically
build the container (with podman or docker), name it `localhost/oxidized` and
give it the tags `latest` and `<branchname>-<sha-tag>`, for example
`localhost/oxidized:master-65baab9`.

## Set up an environment for the container
Once you've built the container (or chosen to make use of the automatically
built container in Docker Hub, which will be downloaded for you by docker on the
first `run` command had you not built it), you need to set up an environment
for the container.

First, you need a configuration directory in the host system that you can map
in the container. You can choose any directory you want, we'll take
`~/oxidized-config` in our example. Don't forget to adjust the permissions as
explained above.

If you already have a configuration for oxidized (`config`), you can skip this
step. Just save it under `~/oxidized-config` and run the container (see below).

If you don't have a configuration, you can make oxidized produce one for you, so
that you just have to adapt it to your needs.

```shell
sudo docker run --rm -v ~/oxidized-config:/home/oxidized/.config/oxidized docker.io/oxidized/oxidized:latest su - oxidized -c oxidized
```
```shell
podman run --rm -v ~/oxidized-config:/home/oxidized/.config/oxidized docker.io/oxidized/oxidized:latest su - oxidized -c oxidized
```

- `--rm` tells docker to automatically remove the container when he exits
- `-v ~/oxidized-config:/home/oxidized/.config/oxidized` maps your local
  `~/oxidized-config` into `/home/oxidized/.config/oxidized`in the container
  environment.
- `su - oxidized -c oxidized` runs oxidized under the user oxidized, so that it
  can produce a configuration under `/home/oxidized/.config/oxidized`


This will return `edit /home/oxidized/.config/oxidized/config`, which is the
path in the container context. Now you can edit `~/oxidized-config/config` to
fit your needs.

You can reiterate this process a few times, until oxidized is happy with the
config, an then you're finished with setting up the environment.


You also need to create the `router.db` file under
`~/oxidized-config/config/router.db` (see
[CSV Source](/docs/Sources.md#source-csv) for further info) or configure another
source to suit your needs. Don't forget to set the file permissions (owner)
properly!



## Run the container
Now you can run the container without specifying an entry point. It will
automatically start oxidized and every other process needed.
```shell
sudo docker run --rm -v ~/oxidized-config:/home/oxidized/.config/oxidized -p 8888:8888/tcp docker.io/oxidized/oxidized:latest
```
```shell
podman run --rm -v ~/oxidized-config:/home/oxidized/.config/oxidized -p 8888:8888/tcp docker.io/oxidized/oxidized:latest
```

`-p 8888:8888/tcp` maps the TCP port 8888 in the container with the port
8888 on the host, so that you can access the RESTful API and Web Interface
from the host.
If the RESTful API and Web Interface should be enabled, edit the
configuration (in our example `~/oxidized-config/config`) and modify
`rest: 127.0.0.1:8888` to `rest: 0.0.0.0:8888`. This will bind port 8888 to all
interfaces, and expose the port so that it can be accessed externally.
[(Issue #445)](https://github.com/ytti/oxidized/issues/445)


## Run with with docker-compose / podman-compose
Alternatively, you can use docker-compose or podman-compose to run the
container:

```yaml
# docker-compose.yml
# docker-compose file example for oxidized that will start along with docker daemon
---
version: "3"
services:
  oxidized:
    restart: always
    image: docker.io/oxidized/oxidized:latest
    ports:
      - 8888:8888/tcp
    environment:
      # Reload hosts list once per day
      CONFIG_RELOAD_INTERVAL: 86400
    volumes:
       - ~/oxidized-config/config:/home/oxidized/.config/oxidized/
```

To start the pod, use `docker-compose up` or `podman-compose down`.

## Special configurations of the official container
### Reload the configuration
If you want to have the config automatically reloaded (e.g. when using a http
source that changes), you need to set the environment variable
CONFIG_RELOAD_INTERVAL. This can be done in `docker-compose.yml` (see above) or
on the command line:

```shell
sudo docker run -v ~/oxidized-config:/home/oxidized/.config/oxidized -p 8888:8888/tcp -e CONFIG_RELOAD_INTERVAL=3600 docker.io/oxidized/oxidized:latest
```
### Use an internal CA
If you need to use an internal CA (e.g. to connect to an private github instance):

```shell
docker run -v /etc/oxidized:/home/oxidized/.config/oxidized -v /path/to/MY-CA.crt:/usr/local/share/ca-certificates/MY-CA.crt -p 8888:8888/tcp -e UPDATE_CA_CERTIFICATES=true -t oxidized/oxidized:latest
```

### Pass the ssh passphrase for a remote git
If you don't want to authenticate with user & password but with a ssh-key, you
can set the ssh passphrase with the environment variable
`OXIDIZED_SSH_PASSPHRASE`

## Tipps & tricks
### podman & Debian Bookworm
To install podman in Debian Bookwork, you need following packages:
```shell
sudo apt install podman containers-storage podman-compose
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

If not, a quick way to solve it is to delete `~/.local/share/containers/`.
Beware - this will delete **all** your containers!

### Store the ssh keys a remote git repository
When you use the githubrepo hook to upload your configs to a remote git
repository, you have to store your ssh-key and the public keys of the remote
server. Create a directory `~/oxidized-ssh` and map it to `/home/oxidized/.ssh`.


To generate an ssh-key, run:
```shell
ssh-keygen -q -t ed25519 -C "Oxidized Push Key@`hostname`" -N "YOURPASSPHRASE" -m PEM -f ~/oxidized-ssh/oxidized-key
```

You also need to store the public keys of the remote git server in known_hosts.
If you don't store the keys, oxidized will refuse to push to the remote Git with
the error
`#<Rugged::SshError: invalid or unknown remote ssh hostkey>`, see Issue #2753.

```shell
ssh-keyscan git-server.example.com > ~/oxidized-ssh/known_hosts
```

Don't forget to set the permission (owner) of the files for the user oxidized
inside the container, or this will not work!
