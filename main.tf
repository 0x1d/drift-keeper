terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.13.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "linode" {
  token = var.linode_token
}

locals {
  monitoring_config = {
    env = base64encode(templatefile("templates/monitoring/env.monitoring.tpl", var.monitoring))
    prometheus = base64encode(templatefile("templates/monitoring/prometheus/prometheus.yml.tpl", {
      wallet_address = var.bot.wallet_address
    }))
    prometheus_web = base64encode(templatefile("templates/monitoring/prometheus/web.yml.tpl", {
      prometheus_password_bcrypt = bcrypt(var.monitoring.prometheus_password)
    }))
  }
  cloud_config = { for s in concat(var.linode_instances, var.digitalocean_instances) : s.label => templatefile("cloud-init/cloud-config.yaml", {
    ntp_server = s.ntp_server
    env_file = base64encode(templatefile("templates/bot/env.tpl", merge(var.bot, {
      jito_block_engine_url = s.jito_block_engine_url
    })))
    config_file = base64encode(templatefile("templates/bot/config.yaml.tpl", {
      use_jito = s.use_jito
    }))
    env_monitoring_file    = local.monitoring_config.env
    prometheus_config_file = local.monitoring_config.prometheus
    prometheus_web_file    = local.monitoring_config.prometheus_web
    docker_compose_file = base64encode(templatefile("templates/bot/docker-compose.yaml.tpl", {
      docker_image = var.bot.docker_image
      docker_image_wallet_tracker = var.bot.docker_image_wallet_tracker
    }))
  }) }
}

resource "linode_sshkey" "master" {
  label   = "master-key"
  ssh_key = chomp(file("~/.ssh/id_rsa.pub"))
}

resource "digitalocean_ssh_key" "default" {
  name       = "master-key"
  public_key = chomp(file("~/.ssh/id_rsa.pub"))
}

resource "linode_instance" "keeper" {
  for_each        = { for s in var.linode_instances : s.label => s }
  label           = each.key
  image           = each.value.image
  group           = each.value.group
  region          = each.value.region
  type            = each.value.type
  authorized_keys = [linode_sshkey.master.ssh_key]
  metadata {
    user_data = base64encode(local.cloud_config[each.key])
  }
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }
}

resource "digitalocean_droplet" "keeper" {
  for_each  = { for s in var.digitalocean_instances : s.label => s }
  image     = each.value.image
  name      = each.key
  region    = each.value.region
  size      = each.value.type
  ssh_keys  = [digitalocean_ssh_key.default.fingerprint]
  user_data = local.cloud_config[each.key]
  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

output "instances" {
  value = merge(
    tomap({ for k, v in linode_instance.keeper : k => v.ip_address }),
    tomap({ for k, v in digitalocean_droplet.keeper : k => v.ipv4_address })
  )
}


output "panopticonf" {
  value = templatefile("templates/monitoring/prometheus/panopticon.yml.tpl", {
    user = "prom"
    password = var.monitoring.prometheus_password
    targets = <<-EOT
      %{for k, v in merge(
    tomap({ for k, v in linode_instance.keeper : k => v.ip_address }),
    tomap({ for k, v in digitalocean_droplet.keeper : k => v.ipv4_address })
  )}
          - targets: ['${v}:9090']
            labels:
              server: ${k}
    %{endfor}
    EOT
  })
}

output "configurations" {
  value = local.cloud_config
}
