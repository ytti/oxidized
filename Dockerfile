# Single-stage build of an oxidized container from phusion/baseimage-docker jammy-1.0.1, derived from Ubuntu 22.04 (Jammy Jellyfish)
FROM docker.io/phusion/baseimage:jammy-1.0.1

# set up dependencies for the build process
RUN apt-get -yq update \
    && apt-get -yq --no-install-recommends install ruby3.0 ruby3.0-dev libssl3 bzip2 libssl-dev pkg-config make cmake libssh2-1 libssh2-1-dev git git-email libmailtools-perl g++ libffi-dev ruby-bundler libicu70 libicu-dev libsqlite3-0 libsqlite3-dev libmysqlclient21 libmysqlclient-dev libpq5 libpq-dev zlib1g-dev msmtp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# dependencies for hooks
RUN gem install --no-document aws-sdk slack-ruby-client xmpp4r cisco_spark

# dependencies for sources
RUN gem install --no-document gpgme sequel sqlite3 mysql2 pg

# dependencies for inputs
RUN gem install --no-document net-tftp net-http-persistent mechanize

# build and install oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

# docker automated build gets shallow copy, but non-shallow copy cannot be unshallowed
RUN git fetch --unshallow || true

# Ensure rugged is built with ssh support
RUN CMAKE_FLAGS='-DUSE_SSH=ON' rake install

# web interface
RUN gem install oxidized-web --no-document

# clean up
WORKDIR /
RUN rm -rf /tmp/oxidized
RUN apt-get -yq --purge autoremove ruby-dev pkg-config make cmake ruby-bundler libssl-dev libssh2-1-dev libicu-dev libsqlite3-dev libmysqlclient-dev libpq-dev zlib1g-dev

# add non-privileged user
ARG UID=30000
ARG GID=$UID
RUN groupadd -g "${GID}" -r oxidized && useradd -u "${UID}" -r -m -d /home/oxidized -g oxidized oxidized

# link config for msmtp for easier use.
RUN ln -s /home/oxidized/.config/oxidized/.msmtprc /home/oxidized/

# setup the access to the file
RUN chmod 600 /home/oxidized/.config/oxidized/.msmtprc
RUN chown oxodized:oxidized /home/oxidized/.config/oxidized/.msmtprc

# add runit services
COPY extra/oxidized.runit /etc/service/oxidized/run
COPY extra/auto-reload-config.runit /etc/service/auto-reload-config/run
COPY extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

EXPOSE 8888/tcp
