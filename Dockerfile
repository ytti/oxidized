FROM phusion/baseimage:0.9.22
MAINTAINER Samer Abdel-Hafez <sam@arahant.net>

RUN add-apt-repository ppa:brightbox/ruby-ng && \
	apt-get update && \
  apt-get install -y ruby2.3 ruby2.3-dev libsqlite3-dev libssl-dev pkg-config make cmake libssh2-1-dev git g++
RUN apt-get install -y libgcrypt11-dev dh-autoreconf libgcrypt20-dev chrpath build-essential wget

RUN mkdir -p /tmp/oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized
RUN wget https://launchpad.net/ubuntu/+archive/primary/+files/libssh2_1.7.0-1ubuntu1.debian.tar.xz
RUN wget https://launchpad.net/ubuntu/+archive/primary/+files/libssh2_1.7.0.orig.tar.gz
RUN tar xvf libssh2_1.7.0-1ubuntu1.debian.tar.xz
RUN tar xfv libssh2_1.7.0.orig.tar.gz
RUN mv debian/ libssh2-1.7.0/
WORKDIR /tmp/oxidized/libssh2-1.7.0/
ENV DEB_BUILD_OPTIONS nocheck
RUN dpkg-buildpackage -b
RUN dpkg -i ../libssh*deb

WORKDIR /tmp/oxidized
RUN gem build oxidized.gemspec
RUN gem install oxidized-*.gem

# web interface
RUN gem install oxidized-web --no-ri --no-rdoc

# dependencies for hooks
RUN gem install aws-sdk
RUN gem install slack-api

RUN rm -rf /tmp/oxidized

RUN apt-get remove -y ruby-dev pkg-config make cmake

RUN apt-get -y autoremove

ADD extra/oxidized.runit /etc/service/oxidized/run
ADD extra/auto-reload-config.runit /etc/service/auto-reload-config/run
ADD extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
