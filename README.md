# Drift Keeper Bot

> Keeper Bots in the Drift Protocol keep the protocol operational by performing automated actions as autonomous off-chain agents. Keepers are rewarded depending on the duties that they perform.

More information:
- https://github.com/drift-labs/keeper-bots-v2/
- https://docs.drift.trade/keeper-bots
- https://docs.drift.trade/tutorial-order-matching-bot

## Prerequisites

- Docker, Docker-Compose
- Solana RPC Endpoint
- Solana Private Key for signing transactions
- Jito Private Key for auth to block engine API (optional)

Drift account is setup according to: https://docs.drift.trade/keeper-bots.  
The account can also be set up using the trading app: https://app.drift.trade/.  

## Setup

Create .env file from example and configure all environment variables.

```
cp example.env .env
```

## Build

Clone the keeper-bots repository and build the Docker image.

```
./ctl.sh image build
```

## Run

Run the bot.

```
docker compose up
```

## Metrics

The bot exposes Prometheus metrics that are automatically scraped.  
A Grafana dashboard is exposed on http://localhost:3000 with default username/password: grafana/admin.
