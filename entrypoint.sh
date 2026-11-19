#!/bin/sh
set -e
mkdir -p /config/home /config/magpie /config/cache

# Start the service in the background, then run Caddy in the foreground.
# Per new service, change ONLY the start command below.
# Magpie: `serve --web` starts BOTH the API gateway (3425) and the Web UI (3430).
# (Bare `web` starts only the Web UI — that would leave the gateway down.)
/usr/local/bin/service serve --web &

# Give the service a moment to bind its ports, then start Caddy.
sleep 2

# Caddy in the foreground (keeps the container alive).
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
