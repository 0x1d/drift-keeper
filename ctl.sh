#!/usr/bin/env bash

LAMPORTS_PER_SOL=1000000000
API_ENDPOINT=https://api.mainnet-beta.solana.com/

source .env

function image {
    function build {
        mkdir -p .build
        git clone https://github.com/drift-labs/keeper-bots-v2 -b mainnet-beta .build/keeper-bots-v2
        docker build -f Dockerfile -t ${DOCKER_IMAGE} .build/keeper-bots-v2
        rm -rf .build
    }
    function push {
        docker push ${DOCKER_IMAGE}
    }
    ${@:-}
}

function droplet {
    function provision {
        terraform init
        terraform apply
    }
    function connect {
        ssh keeper@$(terraform output -raw droplet_ip)
    }
    ${@:-}
}

function balance {
    function sol {
        local addr=${1:-$WALLET_ADDRESS}
        local balance=$(curl $API_ENDPOINT -s -X POST -H "Content-Type: application/json" -d '
        {
            "jsonrpc": "2.0", "id": 1,
            "method": "getBalance",
            "params": [
                "'${addr}'"
            ]
        }
        ' | jq .result.value) 
        echo "$(jq -n $balance/$LAMPORTS_PER_SOL)"
    }

    function usdc {
        local addr=${1:-$WALLET_ADDRESS}
        local balance=$(
        curl $API_ENDPOINT -s -X POST -H "Content-Type: application/json" -d '
        {
            "jsonrpc": "2.0", "id": 1,
            "method": "getTokenAccountsByOwner",
            "params": [
            "'${addr}'",
            {
                "mint": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
            },{
                "encoding": "jsonParsed"
            }]
        }' | jq .result.value[0].account.data.parsed.info.tokenAmount.uiAmount)
        echo ${balance}

    }
    ${@:-}
}

${@:-}