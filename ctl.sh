#!/usr/bin/env bash

LAMPORTS_PER_SOL=1000000000
API_ENDPOINT=https://api.mainnet-beta.solana.com/

source .env

##
## Usage: ./ctl.sh COMMAND SUBCOMMAND
##
## ~> build
##    all               Build all images
##    keeper            Build bot image
##    tracker           Build wallet-tracker image
##    autoswap          Build auto-swap image
##
## ~> push
##    all               Push all images to Docker registry
##    keeper            Push bot image to Docker registry
##    tracker           Push tracker image to Docker registry
##    autoswap          Push auto-swaü image to Docker registry
##
## ~> run
##    all               Run the complete stack locally
##    autoswap          Run Auto-Swap locally
##
## ~> infra
##    plan              Plan infrastructure change
##    provision         Provision infrastructure
##    hosts             Show list of servers
##    connect           Connect to a server
##    playbook          Run a maintenance playbook
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
    function all {
        build keeper
        build tracker
    }
    function keeper {
        mkdir -p .build
        git clone https://github.com/drift-labs/keeper-bots-v2 -b mainnet-beta .build/keeper-bots-v2
        #pushd .build/keeper-bots-v2
        #    git checkout 21fd791d142490fe033b5e25719927c106a0aaf2
        #popd
        docker build -f Dockerfile -t ${DOCKER_IMAGE} .build/keeper-bots-v2
        rm -rf .build
    }
    function tracker {
        pushd wallet-tracker
            docker build -t ${DOCKER_IMAGE_WALLET_TRACKER} .
        popd
    }
    function autoswap {
        pushd auto-swap
            docker build -t ${DOCKER_IMAGE_AUTO_SWAP} .
        popd
    }
    function metrics {
        pushd user-metrics
            docker build -t ${DOCKER_IMAGE_USER_METRICS} .
        popd
    }
    ${@:-}
}

function push {
    function all {
        push keeper
        push tracker
    }
    function keeper {
        docker push ${DOCKER_IMAGE}
    }
    function tracker {
        docker push ${DOCKER_IMAGE_WALLET_TRACKER}
    }
    function autoswap {
        docker push ${DOCKER_IMAGE_AUTO_SWAP}
    }
    function metrics {
        docker push ${DOCKER_IMAGE_USER_METRICS}
    }    
    ${@:-}
}

function run {
    function all {
        docker compose up
    }
    function autoswap {
        pushd auto-swap
            npm start
        popd
    }
    function metircs {
        pushd user-metrics
            npm start
        popd
    }
    ${@:-}
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
        | fzf --height=~50 \
        | awk '{print $2}' \
        | xargs -o ssh -l root $@
    }
    function playbook {
        pushd ansible
            ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=accept-new' -i ../inventory.cfg $(fzf --height=~10)
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