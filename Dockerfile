###################
# Stage 1: Prebuild to save space in the final image.

FROM docker.io/phusion/baseimage:noble-1.0.0 AS prebuilder

# install necessary packages for building gems
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# create bundle directory
RUN mkdir -p /usr/local/bundle
ENV GEM_HOME=/usr/local/bundle

###################
# Install the x25519 gem
RUN gem install x25519 --no-document

###################
# build oxidized
COPY . /tmp/oxidized/
WORKDIR /tmp/oxidized

# docker automated build gets shallow copy, but non-shallow copy cannot be unshallowed
RUN git fetch --unshallow || true

# Remove any older gems of oxidized if they exist
RUN rm pkg/* || true

# Ensure rugged is built with ssh support
RUN rake build


###################
# Stage2: build an oxidized container from phusion/baseimage-docker and install x25519 from stage1
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

# copy the compiled gem from the builder stage
COPY --from=prebuilder /usr/local/bundle /usr/local/bundle

# Set environment variables for bundler
ENV GEM_HOME="/usr/local/bundle"
ENV PATH="$GEM_HOME/bin:$PATH"

# gems not available in ubuntu noble
RUN gem install --no-document \
    # dependencies for hooks
    slack-ruby-client cisco_spark \
    # dependencies for specific inputs
    net-tftp

# install oxidized from prebuilder
# The Dockerfile ist version-independent, so use oxidized-*.gem to cach the gem
RUN mkdir -p /tmp/oxidized
COPY --from=prebuilder /tmp/oxidized/pkg/oxidized-*.gem /tmp/oxidized/
RUN gem install /tmp/oxidized/oxidized-*.gem

# install oxidized-web
RUN gem install oxidized-web --no-document

# clean up
WORKDIR /
RUN rm -rf /tmp/oxidized

EXPOSE 8888/tcp
