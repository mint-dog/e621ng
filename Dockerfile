FROM ruby:3.3.1-slim AS ruby-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential cmake git libglib2.0-dev libpq-dev ragel pkg-config \
  xz-utils wget ca-certificates libssl-dev zlib1g-dev libreadline-dev libffi-dev \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

ARG INCLUDE_DEV=false
RUN gem i overmind && if [ "$INCLUDE_DEV" = "true" ]; then \
      BUNDLE_IGNORE_CONFIG=true bundle install -j$(nproc) --without test; \
    else \
      BUNDLE_IGNORE_CONFIG=true bundle install -j$(nproc) --without development test; \
    fi \
 && rm -rf /usr/local/bundle/cache/*.gem \
 && find /usr/local/bundle/gems/ -name "*.c" -delete \
 && find /usr/local/bundle/gems/ -name "*.o" -delete

FROM node:20-slim AS node-builder
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM ruby:3.3.1-slim

WORKDIR /app

# Copy selected node runtime files from the node builder so we can run node-based tools
COPY --from=node-builder /usr/lib /usr/lib
COPY --from=node-builder /usr/local/share /usr/local/share
COPY --from=node-builder /usr/local/lib /usr/local/lib
COPY --from=node-builder /usr/local/include /usr/local/include
COPY --from=node-builder /usr/local/bin /usr/local/bin

ARG INSTALL_CRON=true

# Install runtime packages (after copying node files so packaging doesn't get overwritten)
RUN apt-get update && apt-get install -y --no-install-recommends \
  ffmpeg libvips42 postgresql-client git tzdata sudo ragel tmux \
  libjemalloc2 ca-certificates $(if [ "$INSTALL_CRON" = "true" ]; then echo cron; fi) && rm -rf /var/lib/apt/lists/*

ENV RUBY_YJIT_ENABLE=1

# Set jemalloc preload for runtime only (set after packages are installed)
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Copy gems and js packages
COPY --from=node-builder /app/node_modules node_modules
COPY --from=ruby-builder /usr/local/bundle /usr/local/bundle
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
COPY Procfile.prod /app/Procfile.prod

# Create a user with (potentially) the same id as on the host (Debian-compatible)
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g ${HOST_GID} e621ng || true && \
  useradd -u ${HOST_UID} -g ${HOST_GID} -s /bin/sh -M e621ng || true && \
  usermod -aG sudo e621ng || true && \
  echo "e621ng ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ignore warnings from git about .git permission differences when running as root
RUN git config --global --add safe.directory $(pwd)

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["overmind", "start"]
