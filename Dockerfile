FROM debian:latest
MAINTAINER Samer Abdel-Hafez <sam@arahant.net>

RUN apt-get update && \
	apt-get install -y ruby ruby-dev libsqlite3-dev libssl-dev pkg-config make cmake

RUN gem install oxidized oxidized-web --no-ri --no-rdoc

RUN apt-get remove -y ruby-dev pkg-config make cmake

RUN apt-get -y autoremove