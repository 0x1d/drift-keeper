#!/usr/bin/env bash

LAMPORTS_PER_SOL=1000000000
API_ENDPOINT=https://api.mainnet-beta.solana.com/

source .env

##
## Usage: ./ctl.sh COMMAND SUBCOMMAND
##
## ~> build
##    keeper            Build bot image
##    tracker           Buils wallet-tracker image
##
## ~> push
##    keeper            Push bot image to Docker registry
##    tracker           Push tracker image to Docker registry
##
## ~> run               Run the stack locally
##
## ~> infra
##    plan              Plan infrastructure change
##    provision         Provision infrastructure
##    hosts             Show list of servers
##    connect           Connect to a server
##    playbook          Run a playbook
##
## ~> balance
##    sol               Show SOL balance
##    usdc              Show USDC balance
##

RED="31"
GREEN="32"
GREENBLD="\e[1;${GREEN}m"
REDBOLD="\e[1;${RED}m"
REDITALIC="\e[3;${RED}m"
EC="\e[0m"

function info {
    printf "\n${GREENBLD}Wallet Address:\t$WALLET_ADDRESS${EC}\n"
    printf "${GREENBLD}Environment:\t$ENV${EC}\n"
    sed -n 's/^##//p' ctl.sh
}

function build {
    function keeper {
        mkdir -p .build
        git clone https://github.com/drift-labs/keeper-bots-v2 -b mainnet-beta .build/keeper-bots-v2
        docker build -f Dockerfile -t ${DOCKER_IMAGE} .build/keeper-bots-v2
        rm -rf .build
    }
    function tracker {
        pushd wallet-tracker
            docker build -t ${DOCKER_IMAGE_WALLET_TRACKER} .
        popd
    }
    ${@:-}
}

function push {
    function keeper {
        docker push ${DOCKER_IMAGE}
    }
    function tracker {
        docker push ${DOCKER_IMAGE_WALLET_TRACKER}
    }
    ${@:-}
}

function run {
    docker compose up
}

function infra {
    function plan {
        terraform init
        terraform plan
    }
    function provision {
        terraform init
        terraform apply
        echo "[bots]" > inventory.cfg
        terraform output -json | jq --raw-output ' .instances.value | to_entries[] | .value' >> inventory.cfg
    }
    function hosts {
        terraform output -json | jq --raw-output  '.instances.value | to_entries[] | [.key, .value] | @tsv'
    }
    function connect {
        infra hosts \
        | fzf --height=~10 \
        | awk '{print $2}' \
        | xargs -o ssh -l root $@
    }
    function playbook {
        pushd ansible
            ansible-playbook -i ../inventory.cfg $(fzf --height=~10)
        popd
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

function repl {
    clear
    cat motd
    info
    echo -e "\n${REDBOLD}Enter command...${EC}"
    read -p '~> ';
    clear
    cat motd
    ./ctl.sh ${REPLY}
    printf "\n"
	read -p "Press any key to continue."
    repl
}

${@:-info}