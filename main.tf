terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.13.0"
    }
  }
}

variable "linode_token" {
  description = "Linode access token"
  type        = string
}

variable "bot" {
  description = "Bot configuration"
  type = object({
    wallet_address     = string
    rpc_endpoint       = string
    ws_endpoint        = string
    keeper_private_key = string
    jito_private_key   = string
  })
}

variable "monitoring" {
  description = "Monitoring configuration"
  default = {
    grafana_user        = "admin"
    grafana_password    = "grafana"
    prometheus_password = "prompass"
  }
  type = object({
    grafana_user        = string
    grafana_password    = string
    prometheus_password = string
  })
}

# Nanode 1 = 1CPU 1GB RAM
# g6-nanode-1

locals {
  instances = [
    {
      label                 = "Drift-Keeper-AMS"
      group                 = "keeper"
      image                 = "linode/ubuntu23.10"
      region                = "nl-ams"
      type                  = "g6-standard-1"
      ntp_server            = "ntp.amsterdam.jito.wtf"
      jito_block_engine_url = "amsterdam.mainnet.block-engine.jito.wtf"
      use_jito              = true
    },
    {
      label                 = "Drift-Keeper-FRA"
      group                 = "keeper"
      image                 = "linode/ubuntu23.10"
      region                = "nl-ams"
      type                  = "g6-standard-1"
      ntp_server            = "ntp.frankfurt.jito.wtf"
      jito_block_engine_url = "frankfurt.mainnet.block-engine.jito.wtf"
      use_jito              = true
    },
    {
      label                 = "Drift-Keeper-OSA"
      group                 = "keeper"
      image                 = "linode/ubuntu23.10"
      region                = "jp-osa"
      type                  = "g6-standard-1"
      ntp_server            = "ntp.tokyo.jito.wtf"
      jito_block_engine_url = "tokyo.mainnet.block-engine.jito.wtf"
      use_jito              = true
    },
    {
      label                 = "Drift-Keeper-NYC"
      group                 = "keeper"
      image                 = "linode/ubuntu23.10"
      region                = "us-ord"
      type                  = "g6-standard-1"
      ntp_server            = "ntp.ny.jito.wtf"
      jito_block_engine_url = "ny.mainnet.block-engine.jito.wtf"
      use_jito              = true
    }
  ]
}

provider "linode" {
  token = var.linode_token
}

resource "linode_sshkey" "master" {
  label   = "master-key"
  ssh_key = chomp(file("~/.ssh/id_rsa.pub"))
}

resource "linode_instance" "keeper" {
  for_each        = { for s in local.instances : s.label => s }
  label           = each.key
  image           = each.value.image
  group           = each.value.group
  region          = each.value.region
  type            = each.value.type
  authorized_keys = [linode_sshkey.master.ssh_key]
  metadata {
    user_data = base64encode(templatefile("cloud-config.yaml", {
      ntp_server          = each.value.ntp_server
      env_monitoring_file = base64encode(templatefile("env.monitoring.tpl", var.monitoring))
      env_file = base64encode(templatefile("env.tpl", merge(var.bot, {
        jito_block_engine_url = each.value.jito_block_engine_url
      })))
      config_file = base64encode(templatefile("config.yaml.tpl", {
        use_jito = each.value.use_jito
      }))
      prometheus_config = base64encode(templatefile("prometheus/prometheus.yml.tpl", {
        wallet_address = var.bot.wallet_address
      }))
      prometheus_web_config = base64encode(templatefile("prometheus/web.yml.tpl", {
        prometheus_password_bcrypt = bcrypt(var.monitoring.prometheus_password)
      }))
    }))
  }
  lifecycle {
    ignore_changes = [
      # usage of bcrypt will always trigger a change in the metadata
      # the user_data / cloud-init config is anyway only applied on first-boot
      metadata
    ]
  }
}

output "instances" {
  value = {
    for k, v in linode_instance.keeper : k => v.ip_address
  }
}
