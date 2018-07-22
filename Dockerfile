# -- stage 1: backport libssh2 1.7.0 from zesty for xenial, as githubrepo hook requires it
FROM ubuntu:xenial as libssh2-backport

# set up dependencies for the build process
RUN apt-get -yq update && \
    apt-get -yq install build-essential chrpath debhelper dh-autoreconf libgcrypt20-dev zlib1g-dev

# build libssh2 1.7.0
WORKDIR /tmp/libssh2-build
ADD https://launchpad.net/ubuntu/+archive/primary/+files/libssh2_1.7.0-1ubuntu1.debian.tar.xz .
ADD https://launchpad.net/ubuntu/+archive/primary/+files/libssh2_1.7.0.orig.tar.gz .
RUN tar xvf libssh2_1.7.0.orig.tar.gz
WORKDIR /tmp/libssh2-build/libssh2-1.7.0
RUN tar xvf ../libssh2_1.7.0-1ubuntu1.debian.tar.xz

WORKDIR /tmp/libssh2-build/libssh2-1.7.0
ENV DEB_BUILD_OPTIONS nocheck
RUN dpkg-buildpackage -b

# -- stage 2: build the actual oxidized container
FROM phusion/baseimage:0.10.1
LABEL maintainer="Samer Abdel-Hafez <sam@arahant.net>"

# set up dependencies for the build process
RUN apt-get -yq update && \
    apt-get -yq install ruby2.3 ruby2.3-dev libsqlite3-dev libssl-dev pkg-config make cmake libssh2-1-dev git g++ libffi-dev ruby-bundler libicu-dev

# upgrade libssh2 to self-built backport from stage 1
COPY --from=libssh2-backport \
    /tmp/libssh2-build/libssh2-1_1.7.0-1ubuntu1_amd64.deb \
    /tmp/libssh2-build/libssh2-1-dev_1.7.0-1ubuntu1_amd64.deb \
    /tmp/
RUN dpkg -i /tmp/*.deb

# dependencies for hooks
RUN gem install aws-sdk slack-api xmpp4r cisco_spark

# build and install oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

# docker automated build gets shallow copy, but non-shallow copy cannot be unshallowed
RUN git fetch --unshallow || true
RUN rake install

# web interface
RUN gem install oxidized-web --no-ri --no-rdoc

# clean up
WORKDIR /
RUN rm -rf /tmp/oxidized
RUN rm /tmp/*.deb
RUN apt-get -yq --purge autoremove ruby-dev pkg-config make cmake ruby-bundler

# add runit services
ADD extra/oxidized.runit /etc/service/oxidized/run
ADD extra/auto-reload-config.runit /etc/service/auto-reload-config/run
ADD extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
