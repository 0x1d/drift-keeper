DOCKER_IMAGE=wirelos/drift-keeper:mainnet-beta
DOCKER_IMAGE_WALLET_TRACKER=wirelos/solana-wallet-tracker:latest

ENV=mainnet-beta
ENDPOINT=${rpc_endpoint}
WS_ENDPOINT=${ws_endpoint}

WALLET_ADDRESS=${wallet_address}
KEEPER_PRIVATE_KEY="${keeper_private_key}"
JITO_BLOCK_ENGINE_URL=${jito_block_engine_url}
JITO_AUTH_PRIVATE_KEY="${jito_private_key}"