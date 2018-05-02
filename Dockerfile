FROM ubuntu:bionic

# set up dependencies for the build process
RUN apt-get -yq update && \
    apt-get -yq install build-essential chrpath debhelper dh-autoreconf libgcrypt20-dev zlib1g-dev

# set up dependencies for the build process
RUN apt-get -yq update && \
    apt-get -yq install ruby2.5 ruby2.5-dev libsqlite3-dev libssl-dev pkg-config make cmake libssh2-1-dev git g++ libffi-dev ruby-bundler libicu-dev

# dependencies for hooks
RUN gem install aws-sdk slack-api xmpp4r cisco_spark

# build and install oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

RUN git fetch --unshallow || true
RUN rake install

# web interface
WORKDIR /tmp
RUN git clone https://github.com/ytti/oxidized-web.git
WORKDIR /tmp/oxidized-web
RUN git fetch --unshallow || true
RUN rake install

# clean up
WORKDIR /
RUN rm -rf /tmp/oxidized
RUN rm -rf /tmp/oxidized-web

# add runit services
ADD extra/oxidized.runit /etc/service/oxidized/run
ADD extra/auto-reload-config.runit /etc/service/auto-reload-config/run
ADD extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
