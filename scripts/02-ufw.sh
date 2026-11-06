#!/bin/sh
set -eu
ufw limit ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
