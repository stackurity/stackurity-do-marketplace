#!/bin/bash
# DigitalOcean's img_check fails while the droplet-agent from the base image
# (and its /opt/digitalocean directory) is present. Customers' droplets get the
# agent again from DigitalOcean if they enable it.
set -o errexit
export DEBIAN_FRONTEND=noninteractive
apt-get -y purge droplet-agent || true
apt-get -y purge do-agent || true
rm -rf /opt/digitalocean
