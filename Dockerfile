FROM docker.io/phusion/baseimage:noble-1.0.2

ENV DEBIAN_FRONTEND=noninteractive

##### Place "static" commands at the beginning to optimize image size and build speed
# remove default ubuntu user
RUN userdel -r ubuntu

# add non-privileged user
ARG UID=30000
ARG GID=$UID
RUN groupadd -g "${GID}" -r oxidized && useradd -u "${UID}" -r -m -d /home/oxidized -g oxidized oxidized

# Set Oxidized user's shell to bash
RUN chsh -s /bin/bash oxidized


##### MSMTP - Sending emails
# link config for msmtp for easier use.
# /home/oxidized/.msmtprc is a symbolic link to /home/oxidized/.config/oxidized/.msmtprc
# Create the files as the user oxidized
RUN mkdir -p /home/oxidized/.config/oxidized/ && \
    chmod -R ug=rwX,o= /home/oxidized/.config/ && \
    touch /home/oxidized/.config/oxidized/.msmtprc && \
    chmod -R u=rw,go= /home/oxidized/.config/oxidized/.msmtprc && \
    ln -s /home/oxidized/.config/oxidized/.msmtprc /home/oxidized/ && \
    chown -R oxidized:oxidized /home/oxidized/.config /home/oxidized/.msmtprc

# add runit services
COPY extra/oxidized.runit /etc/service/oxidized/run
COPY extra/auto-reload-config.runit /etc/service/auto-reload-config/run
COPY extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

# set up dependencies for the build process
RUN apt-get -qy update \
    && apt-get -qy upgrade \
    && apt-get -qy --no-install-recommends install ruby \
    # Build process of oxidized from git and git-tools in the container
    git \
    # Allow git send-email from docker image
    git-email libmailtools-perl \
    # Allow sending emails in the docker container
    msmtp \
    # Debuging tools inside the container
    inetutils-telnet \
    # Use ubuntu gems where possible
    # Gems needed by oxidized
    ruby-rugged ruby-slop ruby-psych \
    ruby-net-telnet ruby-net-ssh ruby-net-ftp ruby-ed25519 \
    # Gem dependencies for inputs
    ruby-net-http-persistent ruby-mechanize \
    # Gem dependencies for sources
    ruby-sqlite3 ruby-mysql2 ruby-pg ruby-sequel ruby-gpgme\
    # Gem dependencies for hooks
    ruby-aws-sdk ruby-xmpp4r \
    # Gems needed by oxidized-web
    ruby-charlock-holmes ruby-haml ruby-htmlentities ruby-json \
    puma ruby-sinatra ruby-sinatra-contrib \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# gems not available in ubuntu noble
RUN gem install --no-document \
    # dependencies for hooks
    slack-ruby-client cisco_spark \
    # dependencies for specific inputs
    net-tftp \
    # Net scp is needed in Version >= 4.1.0, which is not available in ubuntu
    net-scp

# Prepare the build of oxidized, copy our workig directory in the container
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

# Install gems which needs a build environment
RUN apt-get -qy update && \
    apt-get -qy install --no-install-recommends \
                        build-essential ruby-dev && \
    ##### X25519 (a.k.a. Curve25519) Elliptic Curve Diffie-Hellman
    gem install x25519 && \
    ##### build & install oxidized from the working repository
    # docker automated build gets shallow copy, but non-shallow copy cannot be unshallowed
    git fetch --unshallow || true && \
    rake install && \
    # install oxidized-web
    gem install oxidized-web --no-document && \
    # remove the packages we do not need.
    apt-get -qy remove build-essential ruby-dev && \
    apt-get -qy autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# clean up
WORKDIR /
RUN rm -rf /tmp/oxidized

EXPOSE 8888/tcp
