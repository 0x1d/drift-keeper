variable "do_token" {
  description = "DigitalOcean access token"
  type        = string
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

variable "linode_instances" {
  description = "List of server configurations for Linode"
  default = [
    {
      label                 = "DK-LN-AMS"
      group                 = "keeper"
      image                 = "linode/ubuntu23.10"
      region                = "nl-ams"
      type                  = "g6-nanode-1"
      ntp_server            = "ntp.amsterdam.jito.wtf"
      jito_block_engine_url = "amsterdam.mainnet.block-engine.jito.wtf"
      use_jito              = true
    },
    {
      label                 = "DK-LN-OSA"
      group                 = "keeper"
      image                 = "linode/ubuntu23.10"
      region                = "jp-osa"
      type                  = "g6-nanode-1"
      ntp_server            = "ntp.tokyo.jito.wtf"
      jito_block_engine_url = "tokyo.mainnet.block-engine.jito.wtf"
      use_jito              = true
    },
  ]
}

variable "digitalocean_instances" {
  description = "List of server configurations for DigitalOcean"
  default = [
    {
      label                 = "DK-DO-FRA"
      image                 = "ubuntu-23-10-x64"
      region                = "fra1"
      type                  = "s-1vcpu-1gb"
      ntp_server            = "ntp.frankfurt.jito.wtf"
      jito_block_engine_url = "frankfurt.mainnet.block-engine.jito.wtf"
      use_jito              = true
    },
    {
      label                 = "DK-DO-NYC"
      image                 = "ubuntu-23-10-x64"
      region                = "nyc1"
      type                  = "s-1vcpu-1gb"
      ntp_server            = "ntp.ny.jito.wtf"
      jito_block_engine_url = "ny.mainnet.block-engine.jito.wtf"
      use_jito              = true
    }
  ]
}
