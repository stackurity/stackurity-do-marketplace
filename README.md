# Stackurity 1-Click App for DigitalOcean Marketplace

This is a Packer template for the self-hosted Stackurity droplet image.

## What goes into the image (and what never does)

- Packer starts a **new** droplet from DigitalOcean's public `ubuntu-24-04-x64` image. It never uses an existing droplet or snapshot. Packer deletes the build droplet once the snapshot is taken.
- The build installs only public software: Docker (from download.docker.com), Caddy (from Caddy's apt repo), and the public images `ghcr.io/stackurity/stackurity:<version>` and `postgres`. It also adds the upstream `deploy/docker-compose.yml` with a small override.
- **No secrets are baked in.** On the customer's first boot, `001_onboot` generates the database password, the `STACKURITY_SECRET_KEY` and a one-time setup token on their droplet. `scripts/98-no-secrets-check.sh` fails the build if any secret file, `.env`, container, volume or authorized key is left in the image.
- DigitalOcean's `90-cleanup.sh` and `99-img-check.sh` (from digitalocean/marketplace-partners) run last.

## Build

```sh
export DIGITALOCEAN_TOKEN=...   # personal access token with write scope
packer init stackurity.pkr.hcl
packer build -var stackurity_version=0.19.2 stackurity.pkr.hcl
```

The build uses a `s-1vcpu-1gb` droplet in `blr1`, which is billed for about 15 minutes. The snapshot is named `stackurity-<version>-ubuntu-24-04-<timestamp>`.

## On the customer's droplet

- The dashboard is at `https://<droplet IP>`, served by Caddy with a self-signed certificate. Stackurity listens on `127.0.0.1:8080` only. The firewall (ufw) allows ports 22, 80 and 443.
- `cat /root/stackurity-setup.txt` shows the one-time setup token, which is used to create the first admin.
- `stackurity-domain stackurity.example.com` switches to the customer's own domain with a Let's Encrypt certificate. Passkeys need a domain.
- Files live in `/opt/stackurity` (`docker-compose.yml`, `docker-compose.override.yml`, `.env`, `secrets/`).

## Release checklist

1. Bump `stackurity_version` to the new release.
2. Refresh `files/opt/stackurity/docker-compose.yml` from `deploy/docker-compose.yml` at that tag, minus the `build:` block.
3. Build the image, then boot a test droplet from the snapshot and check that `https://<ip>/api/v1/meta` shows the version and `setup_required: true`. Destroy the test droplet.
4. Submit the snapshot in the Vendor Portal.
