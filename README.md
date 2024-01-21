# Drift Keeper Bot

> Keeper Bots in the Drift Protocol keep the protocol operational by performing automated actions as autonomous off-chain agents. Keepers are rewarded depending on the duties that they perform.

This repository contains tools to build, run and monitor Keeper bots for Drift on Solana.

More information:
- https://github.com/drift-labs/keeper-bots-v2/
- https://docs.drift.trade/keeper-bots
- https://docs.drift.trade/tutorial-order-matching-bot

## Prerequisites

- Docker, Docker-Compose
- Solana RPC Endpoint
- Solana Private Key for signing transactions
- Jito Private Key for auth to block engine API (optional)
- Terraform (optional)
- DigitalOcean API Key (optional)

Drift account is setup according to: https://docs.drift.trade/keeper-bots.  
The account can also be set up using the DEX app: https://app.drift.trade/.  

## Configure

Create .env file from example and configure all environment variables.

```
cp example.env .env
```

Adjust `config.yaml` as you please.

## Build

Clone the [keeper-bots-v2](https://github.com/drift-labs/keeper-bots-v2/) repository and build the Docker image.

```
./ctl.sh image build
```

## Run

Run the bot.

```
docker compose up
```

## Deploy

Provision a DigitalOcean Droplet and deploy Keeper Bot with current configuration (.env and config.yaml).
By default ~/.ssh/id_rsa.pub is added to DigitalOcean and the Droplet.

```
./ctl.sh droplet provision
```

Wait until Droplet is up and the `droplet_ip` is printed. You may connect to the Droplet using

```
./ctl.sh droplet connect
```

In case somethin went wrong with the provisioning, check the cloud-init-output log at `/var/log/cloud-init-output.log`.

## Metrics

The bot exposes Prometheus metrics that are automatically scraped.  
A Grafana dashboard is exposed on http://localhost:3000 with default username/password: grafana/admin.
