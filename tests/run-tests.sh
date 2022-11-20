#!/usr/bin/bash

set -eE
trap cleanup ERR

FLEXTESA="http://localhost:20001"
CONTRACT_ADDRESS=""

function main() {
    check_requirements
    cd_to_workspace
    echo "Starting end to end tests"
    setup_tests

    cleanup
}

function cleanup() {
    trap - ERR
    set +e
    echo -n "[CLEANUP] removing flextesa instance... "
    docker stop e2e-flextesa
    docker rm e2e-flextesa
    echo "done"
}

function check_requirements {
    docker-compose version > /dev/null
    ligo --version > /dev/null
}

function cd_to_workspace() {
    cd "$(dirname "$0")"
    cd ..
}

function setup_tests() {
    echo -n "starting flextesa instance... "
    docker run --name "e2e-flextesa" -d -e "block_time=2" -p 20001:20000 oxheadalpha/flextesa:latest kathmandubox start
    sleep 10
    echo "done"
    compile_contract
    deploy_contract
}

function compile_contract() {
    cd contract
    ./compile.sh
    cd ..
}

function deploy_contract() {
    cd contract
    ./deploy.sh 20001
    CONTRACT_ADDRESS="$(octez-client --endpoint $FLEXTESA show known contract nft | grep KT1 | tr -d '\r')" ||
    CONTRACT_ADDRESS="$(tezos-client --endpoint $FLEXTESA show known contract nft | grep KT1 | tr -d '\r')"
    cd ..
}

function mint_token() {

}



main