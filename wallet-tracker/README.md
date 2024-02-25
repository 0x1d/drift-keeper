# Wallet-Tracker

## Endpoints

Metrics: /metrics/:wallet-address?  
If a `wallet-address` is provided in the URL, the app will fetch the metrics states from the given address.  
  
If only 1 wallet needs to be tracked, it is also possible to set the `WALLET_ADDRESS` environment variable and just call the `/metrics` path.

## Metrics

Jupiter:
- SOL Price

Solana:
- SOL Balance
- USDC Balance
- SOL Balance in USDC