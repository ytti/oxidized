FROM docker.io/phusion/baseimage:noble-1.0.0

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# enable ssh
RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Add users to login. The password is "oxidized"
RUN useradd -m oxidized -p '$y$j9T$UoDYxDiE.8iBGmoaD/acn1$kVvYvoEIJdKUmIKFVBRYKLIVzmEBP1RKrCM6Vfx.V55' -s /bin/bash
RUN useradd -m admin -p '$y$j9T$UoDYxDiE.8iBGmoaD/acn1$kVvYvoEIJdKUmIKFVBRYKLIVzmEBP1RKrCM6Vfx.V55' -s /bin/bash

