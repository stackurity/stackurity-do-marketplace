#!/bin/bash
# Installs Docker, Caddy and the public Stackurity images on a FRESH Ubuntu droplet.
# Nothing here reads from any existing server: only public apt repos and public images.
set -euo pipefail
: "${STACKURITY_VERSION:?}"
chmod 0755 /var/lib/cloud/scripts/per-instance/001_onboot /usr/local/bin/stackurity-caddyfile /usr/local/bin/stackurity-domain /etc/update-motd.d/99-one-click

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor -o /etc/apt/keyrings/caddy.gpg
echo "deb [signed-by=/etc/apt/keyrings/caddy.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" > /etc/apt/sources.list.d/caddy.list
apt-get -qq update
apt-get -qqy install docker-ce docker-ce-cli containerd.io docker-compose-plugin caddy ufw openssl
systemctl enable docker caddy

echo "$STACKURITY_VERSION" > /opt/stackurity/VERSION
# Pre-pull the public images so the first boot is quick. No containers are created here,
# so the image carries no database, volume or secret.
docker pull "ghcr.io/stackurity/stackurity:${STACKURITY_VERSION}"
docker pull "$(awk '/image: postgres/{print $2}' /opt/stackurity/docker-compose.yml)"
test -z "$(docker ps -aq)"
test -z "$(docker volume ls -q)"
rm -rf /opt/stackurity/secrets /opt/stackurity/.env
