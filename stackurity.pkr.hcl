packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.4.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

variable "do_token" {
  type      = string
  default   = env("DIGITALOCEAN_TOKEN")
  sensitive = true
}
variable "stackurity_version" {
  type    = string
  default = "0.19.2"
}
variable "region" {
  type    = string
  default = "blr1"
}

locals {
  image_name = "stackurity-${var.stackurity_version}-ubuntu-24-04-${formatdate("YYYYMMDDhhmm", timestamp())}"
}

# Always a brand-new droplet from DigitalOcean's public Ubuntu image, deleted by
# Packer after the snapshot. No existing droplet or snapshot is used.
source "digitalocean" "stackurity" {
  api_token     = var.do_token
  image         = "ubuntu-24-04-x64"
  region        = var.region
  size          = "s-1vcpu-1gb"
  ssh_username  = "root"
  snapshot_name = local.image_name
  droplet_name  = "packer-stackurity-build"
}

build {
  sources = ["source.digitalocean.stackurity"]

  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }
  provisioner "shell" {
    inline = ["mkdir -p /opt/stackurity"]
  }
  provisioner "file" {
    source      = "files/etc/"
    destination = "/etc/"
  }
  provisioner "file" {
    source      = "files/opt/"
    destination = "/opt/"
  }
  provisioner "file" {
    source      = "files/usr/"
    destination = "/usr/"
  }
  provisioner "file" {
    source      = "files/var/"
    destination = "/var/"
  }
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "LC_ALL=C",
      "STACKURITY_VERSION=${var.stackurity_version}",
    ]
    scripts = [
      "scripts/01-stackurity.sh",
      "scripts/02-ufw.sh",
      "scripts/03-force-ssh-logout.sh",
      "scripts/90-cleanup.sh",
      "scripts/98-no-secrets-check.sh",
      "scripts/99-img-check.sh",
    ]
  }
}
