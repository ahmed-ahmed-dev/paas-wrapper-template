# paas-wrapper-template
# Wrap an upstream service image with Caddy as a single-port reverse proxy.
# Caddy merges the service's ports into the one HTTP port the platform
# exposes (blitz.cloud only exposes one port, e.g. 8080).
#
# Per new service, change ONLY these three things:
#   1. UPSTREAM_IMAGE + SERVICE_BIN below (image and binary to wrap)
#   2. The ports in Caddyfile (the service's API / Web UI ports)
#   3. The start command in entrypoint.sh
#
# Secrets: this repo holds ZERO keys. The API key lives in the platform's
# environment variables and Caddy reads it via {$API_KEY} in the Caddyfile.

ARG UPSTREAM_IMAGE=ghcr.io/yetone/magpie:latest
ARG SERVICE_BIN=/magpie

FROM ${UPSTREAM_IMAGE} AS upstream

FROM debian:bookworm-slim

ARG SERVICE_BIN

# Caddy (official apt repo) + curl. Python 3 is for plugin runtimes that
# re-login via Python (e.g. magpie-gptfree); remove the python3 lines if
# your service has no Python-based plugin.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg apt-transport-https \
    python3 python3-venv python3-pip && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update && apt-get install -y --no-install-recommends caddy && \
    rm -rf /var/lib/apt/lists/*

# Service binary from the upstream image
COPY --from=upstream ${SERVICE_BIN} /usr/local/bin/service

# Magpie defaults: config lives in /config (persisted by the platform).
# Change these ENV lines if your service uses different paths.
ENV HOME=/config/home \
    XDG_CONFIG_HOME=/config \
    MAGPIE_ADDR=127.0.0.1:3425

VOLUME ["/config"]

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
