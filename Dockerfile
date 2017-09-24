FROM phusion/baseimage:0.9.18
MAINTAINER Samer Abdel-Hafez <sam@arahant.net>

RUN add-apt-repository ppa:brightbox/ruby-ng && \
	apt-get update && \
  apt-get install -y ruby2.3 ruby2.3-dev libsqlite3-dev libssl-dev pkg-config make cmake libssh2-1-dev git g++

RUN mkdir -p /tmp/oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

RUN gem build oxidized.gemspec
RUN gem install oxidized-*.gem

# web interface
RUN gem install oxidized-web --no-ri --no-rdoc

# dependencies for hooks
RUN gem install aws-sdk
RUN gem install slack-api
RUN gem install xmpp4r

RUN rm -rf /tmp/oxidized

RUN apt-get remove -y ruby-dev pkg-config make cmake

RUN apt-get -y autoremove

ADD extra/oxidized.runit /etc/service/oxidized/run
ADD extra/auto-reload-config.runit /etc/service/auto-reload-config/run
ADD extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
