FROM phusion/baseimage:0.9.18
MAINTAINER Samer Abdel-Hafez <sam@arahant.net>

RUN add-apt-repository ppa:brightbox/ruby-ng && \
	apt-get update && \
  apt-get install -y ruby2.3 ruby2.3-dev libsqlite3-dev libssl-dev pkg-config make cmake

RUN gem install oxidized oxidized-web --no-ri --no-rdoc

RUN apt-get remove -y ruby-dev pkg-config make cmake

RUN apt-get -y autoremove

ADD extra/oxidized.runit /etc/service/oxidized/run
ADD extra/auto-reload-config.runit /etc/service/auto-reload-config/run

VOLUME ["/root/.config/oxidized"]
EXPOSE 8888/tcp
