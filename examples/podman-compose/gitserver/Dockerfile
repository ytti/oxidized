FROM docker.io/phusion/baseimage:noble-1.0.0

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# enable ssh
RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Add user for the gitserver. The password is "git"
RUN useradd -m git -p '$6$32WDb0LTFyQkLffy$u15COVx7CQ4tgp4JT4DO4LJ96q/jwFSpuZC3WrllNQDNa6nW1LhJKW9rLV57ak3rj9Ln./aRA85jzeof1B0Gi1' -s /bin/bash -u 30001

# And install git
RUN install_clean git
