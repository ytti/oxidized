# Single-stage build of an oxidized container from phusion/baseimage-docker v0.11, derived from Ubuntu 18.04 (Bionic Beaver)
FROM phusion/baseimage:0.11
LABEL maintainer="Samer Abdel-Hafez <sam@arahant.net>"

# set up dependencies for the build process
RUN apt-get -yq update && \
    apt-get -yq install ruby2.5 ruby2.5-dev libsqlite3-dev libssl-dev pkg-config make cmake libssh2-1-dev git g++ libffi-dev ruby-bundler libicu-dev

# dependencies for hooks
RUN gem install aws-sdk slack-api xmpp4r cisco_spark

# dependencies for sources
RUN gem install gpgme sequel

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
RUN apt-get -yq --purge autoremove ruby-dev pkg-config make cmake ruby-bundler

# add runit services
ADD extra/oxidized.runit /etc/service/oxidized/run
ADD extra/auto-reload-config.runit /etc/service/auto-reload-config/run
ADD extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
