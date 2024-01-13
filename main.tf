terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}
variable "config" {
  default = {
    ntp_server       = "ntp.amsterdam.jito.wtf"
    docker_image     = "wirelos/drift-keeper:mainnet-beta"
  }
}

provider "digitalocean" {
  token = var.do_token
}

locals {
  user_data = templatefile("cloud-config.yaml", {
    ntp_server  = var.config.ntp_server
    env_file    = base64encode(file(".env"))
    config_file = base64encode(file("config.yaml"))
  })
}

resource "digitalocean_ssh_key" "default" {
  name       = "Keeper Key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "digitalocean_droplet" "keeper" {
  image     = "ubuntu-23-10-x64"
  name      = "drift-keeper"
  region    = "ams3"
  size      = "s-1vcpu-1gb-intel"
  ssh_keys  = [digitalocean_ssh_key.default.fingerprint]
  user_data = local.user_data
}

output "droplet_ip" {
    value = digitalocean_droplet.keeper.ipv4_address
}