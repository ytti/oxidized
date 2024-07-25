# Single-stage build of an oxidized container from phusion/baseimage-docker
FROM docker.io/phusion/baseimage:noble-1.0.0

ENV DEBIAN_FRONTEND=noninteractive

##### Place "static" commands at the beginning to optimize image size and build speed
# add non-privileged user
ARG UID=30000
ARG GID=$UID
RUN groupadd -g "${GID}" -r oxidized && useradd -u "${UID}" -r -m -d /home/oxidized -g oxidized oxidized

# link config for msmtp for easier use.
RUN ln -s /home/oxidized/.config/oxidized/.msmtprc /home/oxidized/

# create parent directory & touch required file
RUN mkdir -p /home/oxidized/.config/oxidized/
RUN touch /home/oxidized/.config/oxidized/.msmtprc

# setup the access to the file
RUN chmod 600 /home/oxidized/.msmtprc
RUN chown oxidized:oxidized /home/oxidized/.msmtprc

# add runit services
COPY extra/oxidized.runit /etc/service/oxidized/run
COPY extra/auto-reload-config.runit /etc/service/auto-reload-config/run
COPY extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

# set up dependencies for the build process
RUN apt-get -yq update \
    && apt-get -yq upgrade \
    && apt-get -yq --no-install-recommends install ruby \
    # Build process of oxidized from git (beloww)
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
    ruby-net-telnet ruby-net-ssh ruby-net-ftp ruby-net-scp ruby-ed25519 \
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
    net-tftp

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

EXPOSE 8888/tcp
