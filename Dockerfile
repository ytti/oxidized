FROM phusion/baseimage:0.9.18
MAINTAINER Samer Abdel-Hafez <sam@arahant.net>

RUN add-apt-repository ppa:brightbox/ruby-ng && \
	apt-get update && \
  apt-get install -y ruby2.1 ruby2.1-dev libsqlite3-dev libssl-dev pkg-config make cmake

RUN gem install oxidized oxidized-web --no-ri --no-rdoc

RUN apt-get remove -y ruby-dev pkg-config make cmake

RUN apt-get -y autoremove

ADD extra/oxidized.runit /etc/service/oxidized/run
