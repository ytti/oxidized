# syntax=docker/dockerfile:1.4

# datasource=github-releases depName=phusion/baseimage-docker
FROM scratch AS files

COPY . /

# datasource=github-releases depName=phusion/baseimage-docker
FROM phusion/baseimage:jammy-1.0.0 AS builder

# set up dependencies for the build process
RUN apt-get update -yq && \
    apt-get install -yq --no-install-recommends \
        ruby3.0 ruby3.0-dev bzip2 pkg-config make cmake git g++ \
        ruby-gpgme ruby-bundler \
        libssl3 libssl-dev libssh2-1 libssh2-1-dev \
        libffi-dev libicu70 libicu-dev libsqlite3-0 libsqlite3-dev \
        libmysqlclient21 libmysqlclient-dev libpq5 libpq-dev zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN \
    # dependencies for hooks
    gem install aws-sdk-sns slack-api xmpp4r cisco_spark --no-document && \
    # dependencies for sources - gpgme moved to apt
    gem install sequel sqlite3 mysql2 pg --no-document && \
    # dependencies for inputs
    gem install net-tftp net-http-persistent mechanize --no-document && \
    rm -rf /var/lib/gems/*/cache/*

RUN \
    --mount=type=bind,from=files,target=/tmp/oxidized,rw \
    cd /tmp/oxidized && \
    # docker automated build gets shallow copy,
    # but non-shallow copy cannot be unshallowed
    git fetch --unshallow || true; \
    rake install && \
    # web interface
    gem install oxidized-web --no-document

# clean up
WORKDIR /
RUN \
    apt-get autoremove -yq --purge \
    ruby3.0-dev pkg-config make cmake ruby-bundler g++ \
    libssl-dev libssh2-1-dev libicu-dev libsqlite3-dev libmysqlclient-dev libpq-dev zlib1g-dev

# add runit services
COPY extra/oxidized.runit /etc/service/oxidized/run
COPY extra/auto-reload-config.runit /etc/service/auto-reload-config/run
COPY extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
