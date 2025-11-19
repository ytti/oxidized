FROM docker.io/debian:trixie-slim

##### Place "static" commands at the beginning to optimize image size and build speed

# add non-privileged user
RUN groupadd -g "30000" -r oxidized && \
    useradd -u "30000" -r -m -d /home/oxidized -g oxidized oxidized && \
    chsh -s /bin/bash oxidized 

# See PR #3637 - ruby runs /bin/sh and bash is whished for exec hooks
RUN ln -sf /bin/bash /bin/sh

##### MSMTP - Sending emails
# link config for msmtp for easier use.
# /home/oxidized/.msmtprc is a symbolic link to /home/oxidized/.config/oxidized/.msmtprc
# Create the files as the user oxidized
RUN mkdir -p /home/oxidized/.config/oxidized/ && \
    touch /home/oxidized/.config/oxidized/.msmtprc && \
    ln -s /home/oxidized/.config/oxidized/.msmtprc /home/oxidized/ && \
    chmod -R ug=rwX,o= /home/oxidized/.config/ && \
    chown -R oxidized:oxidized /home/oxidized/

# add runit services
COPY extra/oxidized.runit /etc/service/oxidized/run
COPY extra/auto-reload-config.runit /etc/service/auto-reload-config/run
COPY extra/update-ca-certificates.runit /etc/service/update-ca-certificates/run

# Prepare the build of oxidized, copy our working directory in the container
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

# set up dependencies for the build process
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    # no apt-get upgrade needed, as debian images are rebuilt on security issues
    apt-get install -y --no-install-recommends \
      # runit: lightweight service supervisor
      # dumb-init: proper PID 1 signal handling
      # gosu: run oxidized as the user oxidized
      runit dumb-init gosu \
      # Build tools
      build-essential ruby-dev \
      # Useful tools
      openssh-client vim-tiny inetutils-telnet \
      # Dependencies for /extra scripts
      curl jq \
      # Build process of oxidized from git and git-tools in the container
      git \
      # Allow git send-email from docker image
      git-email libmailtools-perl \
      # Allow sending emails in the docker container
      msmtp \
      # Use debian packaged gems where possible
      # ruby and core gems needed by oxidized
      ruby ruby-rugged ruby-slop \
      # Gem dependencies for inputs
      ruby-net-telnet ruby-net-ssh ruby-net-ftp ruby-ed25519 ruby-net-scp \
      ruby-net-http-persistent ruby-mechanize \
      # Gem dependencies for sources
      ruby-sqlite3 ruby-mysql2 ruby-pg ruby-sequel ruby-gpgme\
      # Gem dependencies for hooks
      ruby-aws-sdk ruby-xmpp4r \
      # Gems needed by oxidized-web
      ruby-charlock-holmes ruby-haml ruby-htmlentities ruby-json \
      puma ruby-sinatra ruby-sinatra-contrib \
      # Gems needed by slack-ruby-client
      ruby-faraday ruby-faraday-net-http ruby-faraday-multipart ruby-hashie \
      # Gems needed by semantic logger
      ruby-concurrent \
    ; \
    # build & install oxidized from the working repository
    # docker automated build gets shallow copy, but non-shallow copy cannot be unshallowed
    git fetch --unshallow || true; \
    rake install; \
    # install oxidized-web and gems not available in debian trixie
    gem install --no-document --no-wrappers --conservative --minimal-deps \
      oxidized-web \
      # dependencies for hooks
      slack-ruby-client cisco_spark \
      # dependencies for specific inputs
      net-tftp \
      ##### X25519 (a.k.a. Curve25519) Elliptic Curve Diffie-Hellman
      x25519 \
    ; \
    # remove the packages we do not need.
    apt-get remove -y build-essential ruby-dev; \
    apt-get autoremove -y ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    find /var/lib/gems/*/cache -mindepth 1 -delete; \
    rm -rf /tmp/oxidized;

WORKDIR /

EXPOSE 8888/tcp

# dumb-init handles PID 1 for proper signal forwarding (Ctrl-C, SIGTERM)
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# runit supervises all services in /etc/service/
CMD ["runsvdir", "-P", "/etc/service"]
